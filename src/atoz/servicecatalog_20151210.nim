
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_AcceptPortfolioShare_612996 = ref object of OpenApiRestCall_612658
proc url_AcceptPortfolioShare_612998(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptPortfolioShare_612997(path: JsonNode; query: JsonNode;
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AcceptPortfolioShare"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_AcceptPortfolioShare_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an offer to share the specified portfolio.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AcceptPortfolioShare_612996; body: JsonNode): Recallable =
  ## acceptPortfolioShare
  ## Accepts an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var acceptPortfolioShare* = Call_AcceptPortfolioShare_612996(
    name: "acceptPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare",
    validator: validate_AcceptPortfolioShare_612997, base: "/",
    url: url_AcceptPortfolioShare_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateBudgetWithResource_613265 = ref object of OpenApiRestCall_612658
proc url_AssociateBudgetWithResource_613267(protocol: Scheme; host: string;
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

proc validate_AssociateBudgetWithResource_613266(path: JsonNode; query: JsonNode;
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateBudgetWithResource"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_AssociateBudgetWithResource_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified budget with the specified resource.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_AssociateBudgetWithResource_613265; body: JsonNode): Recallable =
  ## associateBudgetWithResource
  ## Associates the specified budget with the specified resource.
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var associateBudgetWithResource* = Call_AssociateBudgetWithResource_613265(
    name: "associateBudgetWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource",
    validator: validate_AssociateBudgetWithResource_613266, base: "/",
    url: url_AssociateBudgetWithResource_613267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePrincipalWithPortfolio_613280 = ref object of OpenApiRestCall_612658
proc url_AssociatePrincipalWithPortfolio_613282(protocol: Scheme; host: string;
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

proc validate_AssociatePrincipalWithPortfolio_613281(path: JsonNode;
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
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_AssociatePrincipalWithPortfolio_613280;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified principal ARN with the specified portfolio.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_AssociatePrincipalWithPortfolio_613280; body: JsonNode): Recallable =
  ## associatePrincipalWithPortfolio
  ## Associates the specified principal ARN with the specified portfolio.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var associatePrincipalWithPortfolio* = Call_AssociatePrincipalWithPortfolio_613280(
    name: "associatePrincipalWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio",
    validator: validate_AssociatePrincipalWithPortfolio_613281, base: "/",
    url: url_AssociatePrincipalWithPortfolio_613282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateProductWithPortfolio_613295 = ref object of OpenApiRestCall_612658
proc url_AssociateProductWithPortfolio_613297(protocol: Scheme; host: string;
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

proc validate_AssociateProductWithPortfolio_613296(path: JsonNode; query: JsonNode;
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
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateProductWithPortfolio"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_AssociateProductWithPortfolio_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified product with the specified portfolio.
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_AssociateProductWithPortfolio_613295; body: JsonNode): Recallable =
  ## associateProductWithPortfolio
  ## Associates the specified product with the specified portfolio.
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var associateProductWithPortfolio* = Call_AssociateProductWithPortfolio_613295(
    name: "associateProductWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio",
    validator: validate_AssociateProductWithPortfolio_613296, base: "/",
    url: url_AssociateProductWithPortfolio_613297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceActionWithProvisioningArtifact_613310 = ref object of OpenApiRestCall_612658
proc url_AssociateServiceActionWithProvisioningArtifact_613312(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceActionWithProvisioningArtifact_613311(
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString("AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_AssociateServiceActionWithProvisioningArtifact_613310;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a self-service action with a provisioning artifact.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_AssociateServiceActionWithProvisioningArtifact_613310;
          body: JsonNode): Recallable =
  ## associateServiceActionWithProvisioningArtifact
  ## Associates a self-service action with a provisioning artifact.
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var associateServiceActionWithProvisioningArtifact* = Call_AssociateServiceActionWithProvisioningArtifact_613310(
    name: "associateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact",
    validator: validate_AssociateServiceActionWithProvisioningArtifact_613311,
    base: "/", url: url_AssociateServiceActionWithProvisioningArtifact_613312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTagOptionWithResource_613325 = ref object of OpenApiRestCall_612658
proc url_AssociateTagOptionWithResource_613327(protocol: Scheme; host: string;
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

proc validate_AssociateTagOptionWithResource_613326(path: JsonNode;
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
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateTagOptionWithResource"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_AssociateTagOptionWithResource_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associate the specified TagOption with the specified portfolio or product.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_AssociateTagOptionWithResource_613325; body: JsonNode): Recallable =
  ## associateTagOptionWithResource
  ## Associate the specified TagOption with the specified portfolio or product.
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var associateTagOptionWithResource* = Call_AssociateTagOptionWithResource_613325(
    name: "associateTagOptionWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource",
    validator: validate_AssociateTagOptionWithResource_613326, base: "/",
    url: url_AssociateTagOptionWithResource_613327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateServiceActionWithProvisioningArtifact_613340 = ref object of OpenApiRestCall_612658
proc url_BatchAssociateServiceActionWithProvisioningArtifact_613342(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
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

proc validate_BatchAssociateServiceActionWithProvisioningArtifact_613341(
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_BatchAssociateServiceActionWithProvisioningArtifact_613340;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates multiple self-service actions with provisioning artifacts.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_BatchAssociateServiceActionWithProvisioningArtifact_613340;
          body: JsonNode): Recallable =
  ## batchAssociateServiceActionWithProvisioningArtifact
  ## Associates multiple self-service actions with provisioning artifacts.
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var batchAssociateServiceActionWithProvisioningArtifact* = Call_BatchAssociateServiceActionWithProvisioningArtifact_613340(
    name: "batchAssociateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact",
    validator: validate_BatchAssociateServiceActionWithProvisioningArtifact_613341,
    base: "/", url: url_BatchAssociateServiceActionWithProvisioningArtifact_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateServiceActionFromProvisioningArtifact_613355 = ref object of OpenApiRestCall_612658
proc url_BatchDisassociateServiceActionFromProvisioningArtifact_613357(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
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

proc validate_BatchDisassociateServiceActionFromProvisioningArtifact_613356(
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_BatchDisassociateServiceActionFromProvisioningArtifact_613355;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_BatchDisassociateServiceActionFromProvisioningArtifact_613355;
          body: JsonNode): Recallable =
  ## batchDisassociateServiceActionFromProvisioningArtifact
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var batchDisassociateServiceActionFromProvisioningArtifact* = Call_BatchDisassociateServiceActionFromProvisioningArtifact_613355(
    name: "batchDisassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact",
    validator: validate_BatchDisassociateServiceActionFromProvisioningArtifact_613356,
    base: "/", url: url_BatchDisassociateServiceActionFromProvisioningArtifact_613357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyProduct_613370 = ref object of OpenApiRestCall_612658
proc url_CopyProduct_613372(protocol: Scheme; host: string; base: string;
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

proc validate_CopyProduct_613371(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CopyProduct"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_CopyProduct_613370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_CopyProduct_613370; body: JsonNode): Recallable =
  ## copyProduct
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var copyProduct* = Call_CopyProduct_613370(name: "copyProduct",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct",
                                        validator: validate_CopyProduct_613371,
                                        base: "/", url: url_CopyProduct_613372,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConstraint_613385 = ref object of OpenApiRestCall_612658
proc url_CreateConstraint_613387(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConstraint_613386(path: JsonNode; query: JsonNode;
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
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateConstraint"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_CreateConstraint_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a constraint.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_CreateConstraint_613385; body: JsonNode): Recallable =
  ## createConstraint
  ## Creates a constraint.
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var createConstraint* = Call_CreateConstraint_613385(name: "createConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint",
    validator: validate_CreateConstraint_613386, base: "/",
    url: url_CreateConstraint_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolio_613400 = ref object of OpenApiRestCall_612658
proc url_CreatePortfolio_613402(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePortfolio_613401(path: JsonNode; query: JsonNode;
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolio"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_CreatePortfolio_613400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a portfolio.
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_CreatePortfolio_613400; body: JsonNode): Recallable =
  ## createPortfolio
  ## Creates a portfolio.
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var createPortfolio* = Call_CreatePortfolio_613400(name: "createPortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio",
    validator: validate_CreatePortfolio_613401, base: "/", url: url_CreatePortfolio_613402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolioShare_613415 = ref object of OpenApiRestCall_612658
proc url_CreatePortfolioShare_613417(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePortfolioShare_613416(path: JsonNode; query: JsonNode;
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
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolioShare"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_CreatePortfolioShare_613415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_CreatePortfolioShare_613415; body: JsonNode): Recallable =
  ## createPortfolioShare
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var createPortfolioShare* = Call_CreatePortfolioShare_613415(
    name: "createPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare",
    validator: validate_CreatePortfolioShare_613416, base: "/",
    url: url_CreatePortfolioShare_613417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProduct_613430 = ref object of OpenApiRestCall_612658
proc url_CreateProduct_613432(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProduct_613431(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613433 = header.getOrDefault("X-Amz-Target")
  valid_613433 = validateParameter(valid_613433, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProduct"))
  if valid_613433 != nil:
    section.add "X-Amz-Target", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_CreateProduct_613430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a product.
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_CreateProduct_613430; body: JsonNode): Recallable =
  ## createProduct
  ## Creates a product.
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var createProduct* = Call_CreateProduct_613430(name: "createProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct",
    validator: validate_CreateProduct_613431, base: "/", url: url_CreateProduct_613432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisionedProductPlan_613445 = ref object of OpenApiRestCall_612658
proc url_CreateProvisionedProductPlan_613447(protocol: Scheme; host: string;
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

proc validate_CreateProvisionedProductPlan_613446(path: JsonNode; query: JsonNode;
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
  var valid_613448 = header.getOrDefault("X-Amz-Target")
  valid_613448 = validateParameter(valid_613448, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisionedProductPlan"))
  if valid_613448 != nil:
    section.add "X-Amz-Target", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Signature")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Signature", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Content-Sha256", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Date")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Date", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Credential")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Credential", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Security-Token")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Security-Token", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Algorithm")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Algorithm", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-SignedHeaders", valid_613455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_CreateProvisionedProductPlan_613445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_CreateProvisionedProductPlan_613445; body: JsonNode): Recallable =
  ## createProvisionedProductPlan
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var createProvisionedProductPlan* = Call_CreateProvisionedProductPlan_613445(
    name: "createProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan",
    validator: validate_CreateProvisionedProductPlan_613446, base: "/",
    url: url_CreateProvisionedProductPlan_613447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisioningArtifact_613460 = ref object of OpenApiRestCall_612658
proc url_CreateProvisioningArtifact_613462(protocol: Scheme; host: string;
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

proc validate_CreateProvisioningArtifact_613461(path: JsonNode; query: JsonNode;
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
  var valid_613463 = header.getOrDefault("X-Amz-Target")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisioningArtifact"))
  if valid_613463 != nil:
    section.add "X-Amz-Target", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_CreateProvisioningArtifact_613460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_CreateProvisioningArtifact_613460; body: JsonNode): Recallable =
  ## createProvisioningArtifact
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var createProvisioningArtifact* = Call_CreateProvisioningArtifact_613460(
    name: "createProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact",
    validator: validate_CreateProvisioningArtifact_613461, base: "/",
    url: url_CreateProvisioningArtifact_613462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServiceAction_613475 = ref object of OpenApiRestCall_612658
proc url_CreateServiceAction_613477(protocol: Scheme; host: string; base: string;
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

proc validate_CreateServiceAction_613476(path: JsonNode; query: JsonNode;
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
  var valid_613478 = header.getOrDefault("X-Amz-Target")
  valid_613478 = validateParameter(valid_613478, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateServiceAction"))
  if valid_613478 != nil:
    section.add "X-Amz-Target", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_CreateServiceAction_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a self-service action.
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_CreateServiceAction_613475; body: JsonNode): Recallable =
  ## createServiceAction
  ## Creates a self-service action.
  ##   body: JObject (required)
  var body_613489 = newJObject()
  if body != nil:
    body_613489 = body
  result = call_613488.call(nil, nil, nil, nil, body_613489)

var createServiceAction* = Call_CreateServiceAction_613475(
    name: "createServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction",
    validator: validate_CreateServiceAction_613476, base: "/",
    url: url_CreateServiceAction_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTagOption_613490 = ref object of OpenApiRestCall_612658
proc url_CreateTagOption_613492(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTagOption_613491(path: JsonNode; query: JsonNode;
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
  var valid_613493 = header.getOrDefault("X-Amz-Target")
  valid_613493 = validateParameter(valid_613493, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateTagOption"))
  if valid_613493 != nil:
    section.add "X-Amz-Target", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_CreateTagOption_613490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a TagOption.
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_CreateTagOption_613490; body: JsonNode): Recallable =
  ## createTagOption
  ## Creates a TagOption.
  ##   body: JObject (required)
  var body_613504 = newJObject()
  if body != nil:
    body_613504 = body
  result = call_613503.call(nil, nil, nil, nil, body_613504)

var createTagOption* = Call_CreateTagOption_613490(name: "createTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption",
    validator: validate_CreateTagOption_613491, base: "/", url: url_CreateTagOption_613492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConstraint_613505 = ref object of OpenApiRestCall_612658
proc url_DeleteConstraint_613507(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConstraint_613506(path: JsonNode; query: JsonNode;
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
  var valid_613508 = header.getOrDefault("X-Amz-Target")
  valid_613508 = validateParameter(valid_613508, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteConstraint"))
  if valid_613508 != nil:
    section.add "X-Amz-Target", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613517: Call_DeleteConstraint_613505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified constraint.
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_DeleteConstraint_613505; body: JsonNode): Recallable =
  ## deleteConstraint
  ## Deletes the specified constraint.
  ##   body: JObject (required)
  var body_613519 = newJObject()
  if body != nil:
    body_613519 = body
  result = call_613518.call(nil, nil, nil, nil, body_613519)

var deleteConstraint* = Call_DeleteConstraint_613505(name: "deleteConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint",
    validator: validate_DeleteConstraint_613506, base: "/",
    url: url_DeleteConstraint_613507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolio_613520 = ref object of OpenApiRestCall_612658
proc url_DeletePortfolio_613522(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePortfolio_613521(path: JsonNode; query: JsonNode;
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
  var valid_613523 = header.getOrDefault("X-Amz-Target")
  valid_613523 = validateParameter(valid_613523, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolio"))
  if valid_613523 != nil:
    section.add "X-Amz-Target", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_DeletePortfolio_613520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_DeletePortfolio_613520; body: JsonNode): Recallable =
  ## deletePortfolio
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ##   body: JObject (required)
  var body_613534 = newJObject()
  if body != nil:
    body_613534 = body
  result = call_613533.call(nil, nil, nil, nil, body_613534)

var deletePortfolio* = Call_DeletePortfolio_613520(name: "deletePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio",
    validator: validate_DeletePortfolio_613521, base: "/", url: url_DeletePortfolio_613522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolioShare_613535 = ref object of OpenApiRestCall_612658
proc url_DeletePortfolioShare_613537(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePortfolioShare_613536(path: JsonNode; query: JsonNode;
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
  var valid_613538 = header.getOrDefault("X-Amz-Target")
  valid_613538 = validateParameter(valid_613538, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolioShare"))
  if valid_613538 != nil:
    section.add "X-Amz-Target", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Signature")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Signature", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Content-Sha256", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Date")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Date", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Credential")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Credential", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Security-Token")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Security-Token", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Algorithm")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Algorithm", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-SignedHeaders", valid_613545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613547: Call_DeletePortfolioShare_613535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ## 
  let valid = call_613547.validator(path, query, header, formData, body)
  let scheme = call_613547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613547.url(scheme.get, call_613547.host, call_613547.base,
                         call_613547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613547, url, valid)

proc call*(call_613548: Call_DeletePortfolioShare_613535; body: JsonNode): Recallable =
  ## deletePortfolioShare
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ##   body: JObject (required)
  var body_613549 = newJObject()
  if body != nil:
    body_613549 = body
  result = call_613548.call(nil, nil, nil, nil, body_613549)

var deletePortfolioShare* = Call_DeletePortfolioShare_613535(
    name: "deletePortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare",
    validator: validate_DeletePortfolioShare_613536, base: "/",
    url: url_DeletePortfolioShare_613537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProduct_613550 = ref object of OpenApiRestCall_612658
proc url_DeleteProduct_613552(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProduct_613551(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613553 = header.getOrDefault("X-Amz-Target")
  valid_613553 = validateParameter(valid_613553, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProduct"))
  if valid_613553 != nil:
    section.add "X-Amz-Target", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Signature")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Signature", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Content-Sha256", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Date")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Date", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Credential")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Credential", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Security-Token")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Security-Token", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Algorithm")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Algorithm", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-SignedHeaders", valid_613560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613562: Call_DeleteProduct_613550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ## 
  let valid = call_613562.validator(path, query, header, formData, body)
  let scheme = call_613562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613562.url(scheme.get, call_613562.host, call_613562.base,
                         call_613562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613562, url, valid)

proc call*(call_613563: Call_DeleteProduct_613550; body: JsonNode): Recallable =
  ## deleteProduct
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ##   body: JObject (required)
  var body_613564 = newJObject()
  if body != nil:
    body_613564 = body
  result = call_613563.call(nil, nil, nil, nil, body_613564)

var deleteProduct* = Call_DeleteProduct_613550(name: "deleteProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct",
    validator: validate_DeleteProduct_613551, base: "/", url: url_DeleteProduct_613552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedProductPlan_613565 = ref object of OpenApiRestCall_612658
proc url_DeleteProvisionedProductPlan_613567(protocol: Scheme; host: string;
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

proc validate_DeleteProvisionedProductPlan_613566(path: JsonNode; query: JsonNode;
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
  var valid_613568 = header.getOrDefault("X-Amz-Target")
  valid_613568 = validateParameter(valid_613568, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisionedProductPlan"))
  if valid_613568 != nil:
    section.add "X-Amz-Target", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_DeleteProvisionedProductPlan_613565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified plan.
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_DeleteProvisionedProductPlan_613565; body: JsonNode): Recallable =
  ## deleteProvisionedProductPlan
  ## Deletes the specified plan.
  ##   body: JObject (required)
  var body_613579 = newJObject()
  if body != nil:
    body_613579 = body
  result = call_613578.call(nil, nil, nil, nil, body_613579)

var deleteProvisionedProductPlan* = Call_DeleteProvisionedProductPlan_613565(
    name: "deleteProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan",
    validator: validate_DeleteProvisionedProductPlan_613566, base: "/",
    url: url_DeleteProvisionedProductPlan_613567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisioningArtifact_613580 = ref object of OpenApiRestCall_612658
proc url_DeleteProvisioningArtifact_613582(protocol: Scheme; host: string;
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

proc validate_DeleteProvisioningArtifact_613581(path: JsonNode; query: JsonNode;
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
  var valid_613583 = header.getOrDefault("X-Amz-Target")
  valid_613583 = validateParameter(valid_613583, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisioningArtifact"))
  if valid_613583 != nil:
    section.add "X-Amz-Target", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Signature")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Signature", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Content-Sha256", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Date")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Date", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Credential")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Credential", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Security-Token")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Security-Token", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Algorithm")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Algorithm", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-SignedHeaders", valid_613590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613592: Call_DeleteProvisioningArtifact_613580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ## 
  let valid = call_613592.validator(path, query, header, formData, body)
  let scheme = call_613592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613592.url(scheme.get, call_613592.host, call_613592.base,
                         call_613592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613592, url, valid)

proc call*(call_613593: Call_DeleteProvisioningArtifact_613580; body: JsonNode): Recallable =
  ## deleteProvisioningArtifact
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ##   body: JObject (required)
  var body_613594 = newJObject()
  if body != nil:
    body_613594 = body
  result = call_613593.call(nil, nil, nil, nil, body_613594)

var deleteProvisioningArtifact* = Call_DeleteProvisioningArtifact_613580(
    name: "deleteProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact",
    validator: validate_DeleteProvisioningArtifact_613581, base: "/",
    url: url_DeleteProvisioningArtifact_613582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceAction_613595 = ref object of OpenApiRestCall_612658
proc url_DeleteServiceAction_613597(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteServiceAction_613596(path: JsonNode; query: JsonNode;
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
  var valid_613598 = header.getOrDefault("X-Amz-Target")
  valid_613598 = validateParameter(valid_613598, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteServiceAction"))
  if valid_613598 != nil:
    section.add "X-Amz-Target", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Signature")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Signature", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Content-Sha256", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Date")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Date", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Credential")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Credential", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Security-Token")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Security-Token", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Algorithm")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Algorithm", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-SignedHeaders", valid_613605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613607: Call_DeleteServiceAction_613595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a self-service action.
  ## 
  let valid = call_613607.validator(path, query, header, formData, body)
  let scheme = call_613607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613607.url(scheme.get, call_613607.host, call_613607.base,
                         call_613607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613607, url, valid)

proc call*(call_613608: Call_DeleteServiceAction_613595; body: JsonNode): Recallable =
  ## deleteServiceAction
  ## Deletes a self-service action.
  ##   body: JObject (required)
  var body_613609 = newJObject()
  if body != nil:
    body_613609 = body
  result = call_613608.call(nil, nil, nil, nil, body_613609)

var deleteServiceAction* = Call_DeleteServiceAction_613595(
    name: "deleteServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction",
    validator: validate_DeleteServiceAction_613596, base: "/",
    url: url_DeleteServiceAction_613597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagOption_613610 = ref object of OpenApiRestCall_612658
proc url_DeleteTagOption_613612(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTagOption_613611(path: JsonNode; query: JsonNode;
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
  var valid_613613 = header.getOrDefault("X-Amz-Target")
  valid_613613 = validateParameter(valid_613613, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteTagOption"))
  if valid_613613 != nil:
    section.add "X-Amz-Target", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Signature")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Signature", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Content-Sha256", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Date")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Date", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Credential")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Credential", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Security-Token")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Security-Token", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Algorithm")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Algorithm", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-SignedHeaders", valid_613620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613622: Call_DeleteTagOption_613610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ## 
  let valid = call_613622.validator(path, query, header, formData, body)
  let scheme = call_613622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613622.url(scheme.get, call_613622.host, call_613622.base,
                         call_613622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613622, url, valid)

proc call*(call_613623: Call_DeleteTagOption_613610; body: JsonNode): Recallable =
  ## deleteTagOption
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ##   body: JObject (required)
  var body_613624 = newJObject()
  if body != nil:
    body_613624 = body
  result = call_613623.call(nil, nil, nil, nil, body_613624)

var deleteTagOption* = Call_DeleteTagOption_613610(name: "deleteTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption",
    validator: validate_DeleteTagOption_613611, base: "/", url: url_DeleteTagOption_613612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConstraint_613625 = ref object of OpenApiRestCall_612658
proc url_DescribeConstraint_613627(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeConstraint_613626(path: JsonNode; query: JsonNode;
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
  var valid_613628 = header.getOrDefault("X-Amz-Target")
  valid_613628 = validateParameter(valid_613628, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeConstraint"))
  if valid_613628 != nil:
    section.add "X-Amz-Target", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Signature")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Signature", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Content-Sha256", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Date")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Date", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Credential")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Credential", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Security-Token")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Security-Token", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Algorithm")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Algorithm", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-SignedHeaders", valid_613635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613637: Call_DescribeConstraint_613625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified constraint.
  ## 
  let valid = call_613637.validator(path, query, header, formData, body)
  let scheme = call_613637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613637.url(scheme.get, call_613637.host, call_613637.base,
                         call_613637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613637, url, valid)

proc call*(call_613638: Call_DescribeConstraint_613625; body: JsonNode): Recallable =
  ## describeConstraint
  ## Gets information about the specified constraint.
  ##   body: JObject (required)
  var body_613639 = newJObject()
  if body != nil:
    body_613639 = body
  result = call_613638.call(nil, nil, nil, nil, body_613639)

var describeConstraint* = Call_DescribeConstraint_613625(
    name: "describeConstraint", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint",
    validator: validate_DescribeConstraint_613626, base: "/",
    url: url_DescribeConstraint_613627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyProductStatus_613640 = ref object of OpenApiRestCall_612658
proc url_DescribeCopyProductStatus_613642(protocol: Scheme; host: string;
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

proc validate_DescribeCopyProductStatus_613641(path: JsonNode; query: JsonNode;
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
  var valid_613643 = header.getOrDefault("X-Amz-Target")
  valid_613643 = validateParameter(valid_613643, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeCopyProductStatus"))
  if valid_613643 != nil:
    section.add "X-Amz-Target", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Signature")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Signature", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Content-Sha256", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Date")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Date", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Credential")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Credential", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Security-Token")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Security-Token", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Algorithm")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Algorithm", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-SignedHeaders", valid_613650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613652: Call_DescribeCopyProductStatus_613640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified copy product operation.
  ## 
  let valid = call_613652.validator(path, query, header, formData, body)
  let scheme = call_613652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613652.url(scheme.get, call_613652.host, call_613652.base,
                         call_613652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613652, url, valid)

proc call*(call_613653: Call_DescribeCopyProductStatus_613640; body: JsonNode): Recallable =
  ## describeCopyProductStatus
  ## Gets the status of the specified copy product operation.
  ##   body: JObject (required)
  var body_613654 = newJObject()
  if body != nil:
    body_613654 = body
  result = call_613653.call(nil, nil, nil, nil, body_613654)

var describeCopyProductStatus* = Call_DescribeCopyProductStatus_613640(
    name: "describeCopyProductStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus",
    validator: validate_DescribeCopyProductStatus_613641, base: "/",
    url: url_DescribeCopyProductStatus_613642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolio_613655 = ref object of OpenApiRestCall_612658
proc url_DescribePortfolio_613657(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePortfolio_613656(path: JsonNode; query: JsonNode;
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
  var valid_613658 = header.getOrDefault("X-Amz-Target")
  valid_613658 = validateParameter(valid_613658, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolio"))
  if valid_613658 != nil:
    section.add "X-Amz-Target", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Signature")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Signature", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Content-Sha256", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Date")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Date", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Credential")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Credential", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Security-Token")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Security-Token", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Algorithm")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Algorithm", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-SignedHeaders", valid_613665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613667: Call_DescribePortfolio_613655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified portfolio.
  ## 
  let valid = call_613667.validator(path, query, header, formData, body)
  let scheme = call_613667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613667.url(scheme.get, call_613667.host, call_613667.base,
                         call_613667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613667, url, valid)

proc call*(call_613668: Call_DescribePortfolio_613655; body: JsonNode): Recallable =
  ## describePortfolio
  ## Gets information about the specified portfolio.
  ##   body: JObject (required)
  var body_613669 = newJObject()
  if body != nil:
    body_613669 = body
  result = call_613668.call(nil, nil, nil, nil, body_613669)

var describePortfolio* = Call_DescribePortfolio_613655(name: "describePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio",
    validator: validate_DescribePortfolio_613656, base: "/",
    url: url_DescribePortfolio_613657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolioShareStatus_613670 = ref object of OpenApiRestCall_612658
proc url_DescribePortfolioShareStatus_613672(protocol: Scheme; host: string;
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

proc validate_DescribePortfolioShareStatus_613671(path: JsonNode; query: JsonNode;
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
  var valid_613673 = header.getOrDefault("X-Amz-Target")
  valid_613673 = validateParameter(valid_613673, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolioShareStatus"))
  if valid_613673 != nil:
    section.add "X-Amz-Target", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Signature")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Signature", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Content-Sha256", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Date")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Date", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Credential")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Credential", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Security-Token")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Security-Token", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Algorithm")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Algorithm", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-SignedHeaders", valid_613680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613682: Call_DescribePortfolioShareStatus_613670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ## 
  let valid = call_613682.validator(path, query, header, formData, body)
  let scheme = call_613682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613682.url(scheme.get, call_613682.host, call_613682.base,
                         call_613682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613682, url, valid)

proc call*(call_613683: Call_DescribePortfolioShareStatus_613670; body: JsonNode): Recallable =
  ## describePortfolioShareStatus
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_613684 = newJObject()
  if body != nil:
    body_613684 = body
  result = call_613683.call(nil, nil, nil, nil, body_613684)

var describePortfolioShareStatus* = Call_DescribePortfolioShareStatus_613670(
    name: "describePortfolioShareStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus",
    validator: validate_DescribePortfolioShareStatus_613671, base: "/",
    url: url_DescribePortfolioShareStatus_613672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProduct_613685 = ref object of OpenApiRestCall_612658
proc url_DescribeProduct_613687(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProduct_613686(path: JsonNode; query: JsonNode;
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
  var valid_613688 = header.getOrDefault("X-Amz-Target")
  valid_613688 = validateParameter(valid_613688, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProduct"))
  if valid_613688 != nil:
    section.add "X-Amz-Target", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Signature")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Signature", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Content-Sha256", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Date")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Date", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Credential")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Credential", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Security-Token")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Security-Token", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Algorithm")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Algorithm", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-SignedHeaders", valid_613695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613697: Call_DescribeProduct_613685; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_613697.validator(path, query, header, formData, body)
  let scheme = call_613697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613697.url(scheme.get, call_613697.host, call_613697.base,
                         call_613697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613697, url, valid)

proc call*(call_613698: Call_DescribeProduct_613685; body: JsonNode): Recallable =
  ## describeProduct
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_613699 = newJObject()
  if body != nil:
    body_613699 = body
  result = call_613698.call(nil, nil, nil, nil, body_613699)

var describeProduct* = Call_DescribeProduct_613685(name: "describeProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct",
    validator: validate_DescribeProduct_613686, base: "/", url: url_DescribeProduct_613687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductAsAdmin_613700 = ref object of OpenApiRestCall_612658
proc url_DescribeProductAsAdmin_613702(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProductAsAdmin_613701(path: JsonNode; query: JsonNode;
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
  var valid_613703 = header.getOrDefault("X-Amz-Target")
  valid_613703 = validateParameter(valid_613703, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductAsAdmin"))
  if valid_613703 != nil:
    section.add "X-Amz-Target", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Signature")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Signature", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Content-Sha256", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Date")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Date", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Credential")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Credential", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Security-Token")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Security-Token", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Algorithm")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Algorithm", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-SignedHeaders", valid_613710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613712: Call_DescribeProductAsAdmin_613700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product. This operation is run with administrator access.
  ## 
  let valid = call_613712.validator(path, query, header, formData, body)
  let scheme = call_613712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613712.url(scheme.get, call_613712.host, call_613712.base,
                         call_613712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613712, url, valid)

proc call*(call_613713: Call_DescribeProductAsAdmin_613700; body: JsonNode): Recallable =
  ## describeProductAsAdmin
  ## Gets information about the specified product. This operation is run with administrator access.
  ##   body: JObject (required)
  var body_613714 = newJObject()
  if body != nil:
    body_613714 = body
  result = call_613713.call(nil, nil, nil, nil, body_613714)

var describeProductAsAdmin* = Call_DescribeProductAsAdmin_613700(
    name: "describeProductAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin",
    validator: validate_DescribeProductAsAdmin_613701, base: "/",
    url: url_DescribeProductAsAdmin_613702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductView_613715 = ref object of OpenApiRestCall_612658
proc url_DescribeProductView_613717(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProductView_613716(path: JsonNode; query: JsonNode;
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
  var valid_613718 = header.getOrDefault("X-Amz-Target")
  valid_613718 = validateParameter(valid_613718, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductView"))
  if valid_613718 != nil:
    section.add "X-Amz-Target", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Signature")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Signature", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Content-Sha256", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Date")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Date", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Credential")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Credential", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Security-Token")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Security-Token", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Algorithm")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Algorithm", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-SignedHeaders", valid_613725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613727: Call_DescribeProductView_613715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_613727.validator(path, query, header, formData, body)
  let scheme = call_613727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613727.url(scheme.get, call_613727.host, call_613727.base,
                         call_613727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613727, url, valid)

proc call*(call_613728: Call_DescribeProductView_613715; body: JsonNode): Recallable =
  ## describeProductView
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_613729 = newJObject()
  if body != nil:
    body_613729 = body
  result = call_613728.call(nil, nil, nil, nil, body_613729)

var describeProductView* = Call_DescribeProductView_613715(
    name: "describeProductView", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView",
    validator: validate_DescribeProductView_613716, base: "/",
    url: url_DescribeProductView_613717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProduct_613730 = ref object of OpenApiRestCall_612658
proc url_DescribeProvisionedProduct_613732(protocol: Scheme; host: string;
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

proc validate_DescribeProvisionedProduct_613731(path: JsonNode; query: JsonNode;
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
  var valid_613733 = header.getOrDefault("X-Amz-Target")
  valid_613733 = validateParameter(valid_613733, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProduct"))
  if valid_613733 != nil:
    section.add "X-Amz-Target", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Signature")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Signature", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Content-Sha256", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Date")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Date", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Credential")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Credential", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Security-Token")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Security-Token", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Algorithm")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Algorithm", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-SignedHeaders", valid_613740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613742: Call_DescribeProvisionedProduct_613730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioned product.
  ## 
  let valid = call_613742.validator(path, query, header, formData, body)
  let scheme = call_613742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613742.url(scheme.get, call_613742.host, call_613742.base,
                         call_613742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613742, url, valid)

proc call*(call_613743: Call_DescribeProvisionedProduct_613730; body: JsonNode): Recallable =
  ## describeProvisionedProduct
  ## Gets information about the specified provisioned product.
  ##   body: JObject (required)
  var body_613744 = newJObject()
  if body != nil:
    body_613744 = body
  result = call_613743.call(nil, nil, nil, nil, body_613744)

var describeProvisionedProduct* = Call_DescribeProvisionedProduct_613730(
    name: "describeProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct",
    validator: validate_DescribeProvisionedProduct_613731, base: "/",
    url: url_DescribeProvisionedProduct_613732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProductPlan_613745 = ref object of OpenApiRestCall_612658
proc url_DescribeProvisionedProductPlan_613747(protocol: Scheme; host: string;
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

proc validate_DescribeProvisionedProductPlan_613746(path: JsonNode;
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
  var valid_613748 = header.getOrDefault("X-Amz-Target")
  valid_613748 = validateParameter(valid_613748, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProductPlan"))
  if valid_613748 != nil:
    section.add "X-Amz-Target", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Signature")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Signature", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Content-Sha256", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Date")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Date", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Credential")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Credential", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Security-Token")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Security-Token", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Algorithm")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Algorithm", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-SignedHeaders", valid_613755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613757: Call_DescribeProvisionedProductPlan_613745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the resource changes for the specified plan.
  ## 
  let valid = call_613757.validator(path, query, header, formData, body)
  let scheme = call_613757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613757.url(scheme.get, call_613757.host, call_613757.base,
                         call_613757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613757, url, valid)

proc call*(call_613758: Call_DescribeProvisionedProductPlan_613745; body: JsonNode): Recallable =
  ## describeProvisionedProductPlan
  ## Gets information about the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_613759 = newJObject()
  if body != nil:
    body_613759 = body
  result = call_613758.call(nil, nil, nil, nil, body_613759)

var describeProvisionedProductPlan* = Call_DescribeProvisionedProductPlan_613745(
    name: "describeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan",
    validator: validate_DescribeProvisionedProductPlan_613746, base: "/",
    url: url_DescribeProvisionedProductPlan_613747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningArtifact_613760 = ref object of OpenApiRestCall_612658
proc url_DescribeProvisioningArtifact_613762(protocol: Scheme; host: string;
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

proc validate_DescribeProvisioningArtifact_613761(path: JsonNode; query: JsonNode;
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
  var valid_613763 = header.getOrDefault("X-Amz-Target")
  valid_613763 = validateParameter(valid_613763, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningArtifact"))
  if valid_613763 != nil:
    section.add "X-Amz-Target", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Signature")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Signature", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Content-Sha256", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Date")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Date", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Credential")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Credential", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Security-Token")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Security-Token", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Algorithm")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Algorithm", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-SignedHeaders", valid_613770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613772: Call_DescribeProvisioningArtifact_613760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ## 
  let valid = call_613772.validator(path, query, header, formData, body)
  let scheme = call_613772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613772.url(scheme.get, call_613772.host, call_613772.base,
                         call_613772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613772, url, valid)

proc call*(call_613773: Call_DescribeProvisioningArtifact_613760; body: JsonNode): Recallable =
  ## describeProvisioningArtifact
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ##   body: JObject (required)
  var body_613774 = newJObject()
  if body != nil:
    body_613774 = body
  result = call_613773.call(nil, nil, nil, nil, body_613774)

var describeProvisioningArtifact* = Call_DescribeProvisioningArtifact_613760(
    name: "describeProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact",
    validator: validate_DescribeProvisioningArtifact_613761, base: "/",
    url: url_DescribeProvisioningArtifact_613762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningParameters_613775 = ref object of OpenApiRestCall_612658
proc url_DescribeProvisioningParameters_613777(protocol: Scheme; host: string;
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

proc validate_DescribeProvisioningParameters_613776(path: JsonNode;
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
  var valid_613778 = header.getOrDefault("X-Amz-Target")
  valid_613778 = validateParameter(valid_613778, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningParameters"))
  if valid_613778 != nil:
    section.add "X-Amz-Target", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Signature")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Signature", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Content-Sha256", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Date")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Date", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Credential")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Credential", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Security-Token")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Security-Token", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Algorithm")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Algorithm", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-SignedHeaders", valid_613785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613787: Call_DescribeProvisioningParameters_613775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ## 
  let valid = call_613787.validator(path, query, header, formData, body)
  let scheme = call_613787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613787.url(scheme.get, call_613787.host, call_613787.base,
                         call_613787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613787, url, valid)

proc call*(call_613788: Call_DescribeProvisioningParameters_613775; body: JsonNode): Recallable =
  ## describeProvisioningParameters
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ##   body: JObject (required)
  var body_613789 = newJObject()
  if body != nil:
    body_613789 = body
  result = call_613788.call(nil, nil, nil, nil, body_613789)

var describeProvisioningParameters* = Call_DescribeProvisioningParameters_613775(
    name: "describeProvisioningParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters",
    validator: validate_DescribeProvisioningParameters_613776, base: "/",
    url: url_DescribeProvisioningParameters_613777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecord_613790 = ref object of OpenApiRestCall_612658
proc url_DescribeRecord_613792(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRecord_613791(path: JsonNode; query: JsonNode;
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
  var valid_613793 = header.getOrDefault("X-Amz-Target")
  valid_613793 = validateParameter(valid_613793, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeRecord"))
  if valid_613793 != nil:
    section.add "X-Amz-Target", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Signature")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Signature", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Content-Sha256", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Date")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Date", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Credential")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Credential", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Security-Token")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Security-Token", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Algorithm")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Algorithm", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-SignedHeaders", valid_613800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613802: Call_DescribeRecord_613790; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ## 
  let valid = call_613802.validator(path, query, header, formData, body)
  let scheme = call_613802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613802.url(scheme.get, call_613802.host, call_613802.base,
                         call_613802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613802, url, valid)

proc call*(call_613803: Call_DescribeRecord_613790; body: JsonNode): Recallable =
  ## describeRecord
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ##   body: JObject (required)
  var body_613804 = newJObject()
  if body != nil:
    body_613804 = body
  result = call_613803.call(nil, nil, nil, nil, body_613804)

var describeRecord* = Call_DescribeRecord_613790(name: "describeRecord",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord",
    validator: validate_DescribeRecord_613791, base: "/", url: url_DescribeRecord_613792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceAction_613805 = ref object of OpenApiRestCall_612658
proc url_DescribeServiceAction_613807(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeServiceAction_613806(path: JsonNode; query: JsonNode;
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
  var valid_613808 = header.getOrDefault("X-Amz-Target")
  valid_613808 = validateParameter(valid_613808, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceAction"))
  if valid_613808 != nil:
    section.add "X-Amz-Target", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Signature")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Signature", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Content-Sha256", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Date")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Date", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Credential")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Credential", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Security-Token")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Security-Token", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Algorithm")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Algorithm", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-SignedHeaders", valid_613815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613817: Call_DescribeServiceAction_613805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a self-service action.
  ## 
  let valid = call_613817.validator(path, query, header, formData, body)
  let scheme = call_613817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613817.url(scheme.get, call_613817.host, call_613817.base,
                         call_613817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613817, url, valid)

proc call*(call_613818: Call_DescribeServiceAction_613805; body: JsonNode): Recallable =
  ## describeServiceAction
  ## Describes a self-service action.
  ##   body: JObject (required)
  var body_613819 = newJObject()
  if body != nil:
    body_613819 = body
  result = call_613818.call(nil, nil, nil, nil, body_613819)

var describeServiceAction* = Call_DescribeServiceAction_613805(
    name: "describeServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction",
    validator: validate_DescribeServiceAction_613806, base: "/",
    url: url_DescribeServiceAction_613807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceActionExecutionParameters_613820 = ref object of OpenApiRestCall_612658
proc url_DescribeServiceActionExecutionParameters_613822(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServiceActionExecutionParameters_613821(path: JsonNode;
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
  var valid_613823 = header.getOrDefault("X-Amz-Target")
  valid_613823 = validateParameter(valid_613823, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"))
  if valid_613823 != nil:
    section.add "X-Amz-Target", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Signature")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Signature", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Content-Sha256", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Date")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Date", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Credential")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Credential", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Security-Token")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Security-Token", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Algorithm")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Algorithm", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-SignedHeaders", valid_613830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613832: Call_DescribeServiceActionExecutionParameters_613820;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613832.validator(path, query, header, formData, body)
  let scheme = call_613832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613832.url(scheme.get, call_613832.host, call_613832.base,
                         call_613832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613832, url, valid)

proc call*(call_613833: Call_DescribeServiceActionExecutionParameters_613820;
          body: JsonNode): Recallable =
  ## describeServiceActionExecutionParameters
  ##   body: JObject (required)
  var body_613834 = newJObject()
  if body != nil:
    body_613834 = body
  result = call_613833.call(nil, nil, nil, nil, body_613834)

var describeServiceActionExecutionParameters* = Call_DescribeServiceActionExecutionParameters_613820(
    name: "describeServiceActionExecutionParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters",
    validator: validate_DescribeServiceActionExecutionParameters_613821,
    base: "/", url: url_DescribeServiceActionExecutionParameters_613822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTagOption_613835 = ref object of OpenApiRestCall_612658
proc url_DescribeTagOption_613837(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTagOption_613836(path: JsonNode; query: JsonNode;
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
  var valid_613838 = header.getOrDefault("X-Amz-Target")
  valid_613838 = validateParameter(valid_613838, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeTagOption"))
  if valid_613838 != nil:
    section.add "X-Amz-Target", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-Signature")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-Signature", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Content-Sha256", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-Date")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Date", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Credential")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Credential", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Security-Token")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Security-Token", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Algorithm")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Algorithm", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-SignedHeaders", valid_613845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613847: Call_DescribeTagOption_613835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified TagOption.
  ## 
  let valid = call_613847.validator(path, query, header, formData, body)
  let scheme = call_613847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613847.url(scheme.get, call_613847.host, call_613847.base,
                         call_613847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613847, url, valid)

proc call*(call_613848: Call_DescribeTagOption_613835; body: JsonNode): Recallable =
  ## describeTagOption
  ## Gets information about the specified TagOption.
  ##   body: JObject (required)
  var body_613849 = newJObject()
  if body != nil:
    body_613849 = body
  result = call_613848.call(nil, nil, nil, nil, body_613849)

var describeTagOption* = Call_DescribeTagOption_613835(name: "describeTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption",
    validator: validate_DescribeTagOption_613836, base: "/",
    url: url_DescribeTagOption_613837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSOrganizationsAccess_613850 = ref object of OpenApiRestCall_612658
proc url_DisableAWSOrganizationsAccess_613852(protocol: Scheme; host: string;
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

proc validate_DisableAWSOrganizationsAccess_613851(path: JsonNode; query: JsonNode;
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
  var valid_613853 = header.getOrDefault("X-Amz-Target")
  valid_613853 = validateParameter(valid_613853, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"))
  if valid_613853 != nil:
    section.add "X-Amz-Target", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Signature")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Signature", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Content-Sha256", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Date")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Date", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Credential")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Credential", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Security-Token")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Security-Token", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Algorithm")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Algorithm", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-SignedHeaders", valid_613860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613862: Call_DisableAWSOrganizationsAccess_613850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ## 
  let valid = call_613862.validator(path, query, header, formData, body)
  let scheme = call_613862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613862.url(scheme.get, call_613862.host, call_613862.base,
                         call_613862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613862, url, valid)

proc call*(call_613863: Call_DisableAWSOrganizationsAccess_613850; body: JsonNode): Recallable =
  ## disableAWSOrganizationsAccess
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_613864 = newJObject()
  if body != nil:
    body_613864 = body
  result = call_613863.call(nil, nil, nil, nil, body_613864)

var disableAWSOrganizationsAccess* = Call_DisableAWSOrganizationsAccess_613850(
    name: "disableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess",
    validator: validate_DisableAWSOrganizationsAccess_613851, base: "/",
    url: url_DisableAWSOrganizationsAccess_613852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateBudgetFromResource_613865 = ref object of OpenApiRestCall_612658
proc url_DisassociateBudgetFromResource_613867(protocol: Scheme; host: string;
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

proc validate_DisassociateBudgetFromResource_613866(path: JsonNode;
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
  var valid_613868 = header.getOrDefault("X-Amz-Target")
  valid_613868 = validateParameter(valid_613868, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateBudgetFromResource"))
  if valid_613868 != nil:
    section.add "X-Amz-Target", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Signature")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Signature", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Content-Sha256", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-Date")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-Date", valid_613871
  var valid_613872 = header.getOrDefault("X-Amz-Credential")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "X-Amz-Credential", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-Security-Token")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Security-Token", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Algorithm")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Algorithm", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-SignedHeaders", valid_613875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613877: Call_DisassociateBudgetFromResource_613865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified budget from the specified resource.
  ## 
  let valid = call_613877.validator(path, query, header, formData, body)
  let scheme = call_613877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613877.url(scheme.get, call_613877.host, call_613877.base,
                         call_613877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613877, url, valid)

proc call*(call_613878: Call_DisassociateBudgetFromResource_613865; body: JsonNode): Recallable =
  ## disassociateBudgetFromResource
  ## Disassociates the specified budget from the specified resource.
  ##   body: JObject (required)
  var body_613879 = newJObject()
  if body != nil:
    body_613879 = body
  result = call_613878.call(nil, nil, nil, nil, body_613879)

var disassociateBudgetFromResource* = Call_DisassociateBudgetFromResource_613865(
    name: "disassociateBudgetFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource",
    validator: validate_DisassociateBudgetFromResource_613866, base: "/",
    url: url_DisassociateBudgetFromResource_613867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePrincipalFromPortfolio_613880 = ref object of OpenApiRestCall_612658
proc url_DisassociatePrincipalFromPortfolio_613882(protocol: Scheme; host: string;
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

proc validate_DisassociatePrincipalFromPortfolio_613881(path: JsonNode;
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
  var valid_613883 = header.getOrDefault("X-Amz-Target")
  valid_613883 = validateParameter(valid_613883, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"))
  if valid_613883 != nil:
    section.add "X-Amz-Target", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Signature")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Signature", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Content-Sha256", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Date")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Date", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-Credential")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Credential", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Security-Token")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Security-Token", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Algorithm")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Algorithm", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-SignedHeaders", valid_613890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613892: Call_DisassociatePrincipalFromPortfolio_613880;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ## 
  let valid = call_613892.validator(path, query, header, formData, body)
  let scheme = call_613892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613892.url(scheme.get, call_613892.host, call_613892.base,
                         call_613892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613892, url, valid)

proc call*(call_613893: Call_DisassociatePrincipalFromPortfolio_613880;
          body: JsonNode): Recallable =
  ## disassociatePrincipalFromPortfolio
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ##   body: JObject (required)
  var body_613894 = newJObject()
  if body != nil:
    body_613894 = body
  result = call_613893.call(nil, nil, nil, nil, body_613894)

var disassociatePrincipalFromPortfolio* = Call_DisassociatePrincipalFromPortfolio_613880(
    name: "disassociatePrincipalFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio",
    validator: validate_DisassociatePrincipalFromPortfolio_613881, base: "/",
    url: url_DisassociatePrincipalFromPortfolio_613882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateProductFromPortfolio_613895 = ref object of OpenApiRestCall_612658
proc url_DisassociateProductFromPortfolio_613897(protocol: Scheme; host: string;
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

proc validate_DisassociateProductFromPortfolio_613896(path: JsonNode;
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
  var valid_613898 = header.getOrDefault("X-Amz-Target")
  valid_613898 = validateParameter(valid_613898, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateProductFromPortfolio"))
  if valid_613898 != nil:
    section.add "X-Amz-Target", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Signature")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Signature", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Content-Sha256", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Date")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Date", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Credential")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Credential", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Security-Token")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Security-Token", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-Algorithm")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Algorithm", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-SignedHeaders", valid_613905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613907: Call_DisassociateProductFromPortfolio_613895;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified product from the specified portfolio. 
  ## 
  let valid = call_613907.validator(path, query, header, formData, body)
  let scheme = call_613907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613907.url(scheme.get, call_613907.host, call_613907.base,
                         call_613907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613907, url, valid)

proc call*(call_613908: Call_DisassociateProductFromPortfolio_613895;
          body: JsonNode): Recallable =
  ## disassociateProductFromPortfolio
  ## Disassociates the specified product from the specified portfolio. 
  ##   body: JObject (required)
  var body_613909 = newJObject()
  if body != nil:
    body_613909 = body
  result = call_613908.call(nil, nil, nil, nil, body_613909)

var disassociateProductFromPortfolio* = Call_DisassociateProductFromPortfolio_613895(
    name: "disassociateProductFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio",
    validator: validate_DisassociateProductFromPortfolio_613896, base: "/",
    url: url_DisassociateProductFromPortfolio_613897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceActionFromProvisioningArtifact_613910 = ref object of OpenApiRestCall_612658
proc url_DisassociateServiceActionFromProvisioningArtifact_613912(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
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

proc validate_DisassociateServiceActionFromProvisioningArtifact_613911(
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
  var valid_613913 = header.getOrDefault("X-Amz-Target")
  valid_613913 = validateParameter(valid_613913, JString, required = true, default = newJString("AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"))
  if valid_613913 != nil:
    section.add "X-Amz-Target", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Signature")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Signature", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Content-Sha256", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Date")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Date", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Credential")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Credential", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Security-Token")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Security-Token", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Algorithm")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Algorithm", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-SignedHeaders", valid_613920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613922: Call_DisassociateServiceActionFromProvisioningArtifact_613910;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ## 
  let valid = call_613922.validator(path, query, header, formData, body)
  let scheme = call_613922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613922.url(scheme.get, call_613922.host, call_613922.base,
                         call_613922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613922, url, valid)

proc call*(call_613923: Call_DisassociateServiceActionFromProvisioningArtifact_613910;
          body: JsonNode): Recallable =
  ## disassociateServiceActionFromProvisioningArtifact
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_613924 = newJObject()
  if body != nil:
    body_613924 = body
  result = call_613923.call(nil, nil, nil, nil, body_613924)

var disassociateServiceActionFromProvisioningArtifact* = Call_DisassociateServiceActionFromProvisioningArtifact_613910(
    name: "disassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact",
    validator: validate_DisassociateServiceActionFromProvisioningArtifact_613911,
    base: "/", url: url_DisassociateServiceActionFromProvisioningArtifact_613912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTagOptionFromResource_613925 = ref object of OpenApiRestCall_612658
proc url_DisassociateTagOptionFromResource_613927(protocol: Scheme; host: string;
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

proc validate_DisassociateTagOptionFromResource_613926(path: JsonNode;
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
  var valid_613928 = header.getOrDefault("X-Amz-Target")
  valid_613928 = validateParameter(valid_613928, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateTagOptionFromResource"))
  if valid_613928 != nil:
    section.add "X-Amz-Target", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Signature")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Signature", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Content-Sha256", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Date")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Date", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Credential")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Credential", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Security-Token")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Security-Token", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Algorithm")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Algorithm", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-SignedHeaders", valid_613935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613937: Call_DisassociateTagOptionFromResource_613925;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified TagOption from the specified resource.
  ## 
  let valid = call_613937.validator(path, query, header, formData, body)
  let scheme = call_613937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613937.url(scheme.get, call_613937.host, call_613937.base,
                         call_613937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613937, url, valid)

proc call*(call_613938: Call_DisassociateTagOptionFromResource_613925;
          body: JsonNode): Recallable =
  ## disassociateTagOptionFromResource
  ## Disassociates the specified TagOption from the specified resource.
  ##   body: JObject (required)
  var body_613939 = newJObject()
  if body != nil:
    body_613939 = body
  result = call_613938.call(nil, nil, nil, nil, body_613939)

var disassociateTagOptionFromResource* = Call_DisassociateTagOptionFromResource_613925(
    name: "disassociateTagOptionFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource",
    validator: validate_DisassociateTagOptionFromResource_613926, base: "/",
    url: url_DisassociateTagOptionFromResource_613927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSOrganizationsAccess_613940 = ref object of OpenApiRestCall_612658
proc url_EnableAWSOrganizationsAccess_613942(protocol: Scheme; host: string;
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

proc validate_EnableAWSOrganizationsAccess_613941(path: JsonNode; query: JsonNode;
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
  var valid_613943 = header.getOrDefault("X-Amz-Target")
  valid_613943 = validateParameter(valid_613943, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"))
  if valid_613943 != nil:
    section.add "X-Amz-Target", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Signature")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Signature", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Content-Sha256", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Date")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Date", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Credential")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Credential", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Security-Token")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Security-Token", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-Algorithm")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-Algorithm", valid_613949
  var valid_613950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-SignedHeaders", valid_613950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613952: Call_EnableAWSOrganizationsAccess_613940; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ## 
  let valid = call_613952.validator(path, query, header, formData, body)
  let scheme = call_613952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613952.url(scheme.get, call_613952.host, call_613952.base,
                         call_613952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613952, url, valid)

proc call*(call_613953: Call_EnableAWSOrganizationsAccess_613940; body: JsonNode): Recallable =
  ## enableAWSOrganizationsAccess
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ##   body: JObject (required)
  var body_613954 = newJObject()
  if body != nil:
    body_613954 = body
  result = call_613953.call(nil, nil, nil, nil, body_613954)

var enableAWSOrganizationsAccess* = Call_EnableAWSOrganizationsAccess_613940(
    name: "enableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess",
    validator: validate_EnableAWSOrganizationsAccess_613941, base: "/",
    url: url_EnableAWSOrganizationsAccess_613942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductPlan_613955 = ref object of OpenApiRestCall_612658
proc url_ExecuteProvisionedProductPlan_613957(protocol: Scheme; host: string;
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

proc validate_ExecuteProvisionedProductPlan_613956(path: JsonNode; query: JsonNode;
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
  var valid_613958 = header.getOrDefault("X-Amz-Target")
  valid_613958 = validateParameter(valid_613958, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"))
  if valid_613958 != nil:
    section.add "X-Amz-Target", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Signature")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Signature", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Content-Sha256", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Date")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Date", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Credential")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Credential", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Security-Token")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Security-Token", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Algorithm")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Algorithm", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-SignedHeaders", valid_613965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613967: Call_ExecuteProvisionedProductPlan_613955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ## 
  let valid = call_613967.validator(path, query, header, formData, body)
  let scheme = call_613967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613967.url(scheme.get, call_613967.host, call_613967.base,
                         call_613967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613967, url, valid)

proc call*(call_613968: Call_ExecuteProvisionedProductPlan_613955; body: JsonNode): Recallable =
  ## executeProvisionedProductPlan
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_613969 = newJObject()
  if body != nil:
    body_613969 = body
  result = call_613968.call(nil, nil, nil, nil, body_613969)

var executeProvisionedProductPlan* = Call_ExecuteProvisionedProductPlan_613955(
    name: "executeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan",
    validator: validate_ExecuteProvisionedProductPlan_613956, base: "/",
    url: url_ExecuteProvisionedProductPlan_613957,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductServiceAction_613970 = ref object of OpenApiRestCall_612658
proc url_ExecuteProvisionedProductServiceAction_613972(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteProvisionedProductServiceAction_613971(path: JsonNode;
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
  var valid_613973 = header.getOrDefault("X-Amz-Target")
  valid_613973 = validateParameter(valid_613973, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"))
  if valid_613973 != nil:
    section.add "X-Amz-Target", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-Signature")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Signature", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Content-Sha256", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Date")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Date", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Credential")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Credential", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Security-Token")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Security-Token", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Algorithm")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Algorithm", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-SignedHeaders", valid_613980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613982: Call_ExecuteProvisionedProductServiceAction_613970;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Executes a self-service action against a provisioned product.
  ## 
  let valid = call_613982.validator(path, query, header, formData, body)
  let scheme = call_613982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613982.url(scheme.get, call_613982.host, call_613982.base,
                         call_613982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613982, url, valid)

proc call*(call_613983: Call_ExecuteProvisionedProductServiceAction_613970;
          body: JsonNode): Recallable =
  ## executeProvisionedProductServiceAction
  ## Executes a self-service action against a provisioned product.
  ##   body: JObject (required)
  var body_613984 = newJObject()
  if body != nil:
    body_613984 = body
  result = call_613983.call(nil, nil, nil, nil, body_613984)

var executeProvisionedProductServiceAction* = Call_ExecuteProvisionedProductServiceAction_613970(
    name: "executeProvisionedProductServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction",
    validator: validate_ExecuteProvisionedProductServiceAction_613971, base: "/",
    url: url_ExecuteProvisionedProductServiceAction_613972,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSOrganizationsAccessStatus_613985 = ref object of OpenApiRestCall_612658
proc url_GetAWSOrganizationsAccessStatus_613987(protocol: Scheme; host: string;
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

proc validate_GetAWSOrganizationsAccessStatus_613986(path: JsonNode;
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
  var valid_613988 = header.getOrDefault("X-Amz-Target")
  valid_613988 = validateParameter(valid_613988, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"))
  if valid_613988 != nil:
    section.add "X-Amz-Target", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-Signature")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-Signature", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Content-Sha256", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Date")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Date", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Credential")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Credential", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Security-Token")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Security-Token", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Algorithm")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Algorithm", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-SignedHeaders", valid_613995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613997: Call_GetAWSOrganizationsAccessStatus_613985;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ## 
  let valid = call_613997.validator(path, query, header, formData, body)
  let scheme = call_613997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613997.url(scheme.get, call_613997.host, call_613997.base,
                         call_613997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613997, url, valid)

proc call*(call_613998: Call_GetAWSOrganizationsAccessStatus_613985; body: JsonNode): Recallable =
  ## getAWSOrganizationsAccessStatus
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_613999 = newJObject()
  if body != nil:
    body_613999 = body
  result = call_613998.call(nil, nil, nil, nil, body_613999)

var getAWSOrganizationsAccessStatus* = Call_GetAWSOrganizationsAccessStatus_613985(
    name: "getAWSOrganizationsAccessStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus",
    validator: validate_GetAWSOrganizationsAccessStatus_613986, base: "/",
    url: url_GetAWSOrganizationsAccessStatus_613987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAcceptedPortfolioShares_614000 = ref object of OpenApiRestCall_612658
proc url_ListAcceptedPortfolioShares_614002(protocol: Scheme; host: string;
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

proc validate_ListAcceptedPortfolioShares_614001(path: JsonNode; query: JsonNode;
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
  var valid_614003 = query.getOrDefault("PageToken")
  valid_614003 = validateParameter(valid_614003, JString, required = false,
                                 default = nil)
  if valid_614003 != nil:
    section.add "PageToken", valid_614003
  var valid_614004 = query.getOrDefault("PageSize")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "PageSize", valid_614004
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
  var valid_614005 = header.getOrDefault("X-Amz-Target")
  valid_614005 = validateParameter(valid_614005, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListAcceptedPortfolioShares"))
  if valid_614005 != nil:
    section.add "X-Amz-Target", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-Signature")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Signature", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Content-Sha256", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Date")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Date", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Credential")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Credential", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Security-Token")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Security-Token", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-Algorithm")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Algorithm", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-SignedHeaders", valid_614012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614014: Call_ListAcceptedPortfolioShares_614000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  let valid = call_614014.validator(path, query, header, formData, body)
  let scheme = call_614014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614014.url(scheme.get, call_614014.host, call_614014.base,
                         call_614014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614014, url, valid)

proc call*(call_614015: Call_ListAcceptedPortfolioShares_614000; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listAcceptedPortfolioShares
  ## Lists all portfolios for which sharing was accepted by this account.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614016 = newJObject()
  var body_614017 = newJObject()
  add(query_614016, "PageToken", newJString(PageToken))
  add(query_614016, "PageSize", newJString(PageSize))
  if body != nil:
    body_614017 = body
  result = call_614015.call(nil, query_614016, nil, nil, body_614017)

var listAcceptedPortfolioShares* = Call_ListAcceptedPortfolioShares_614000(
    name: "listAcceptedPortfolioShares", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares",
    validator: validate_ListAcceptedPortfolioShares_614001, base: "/",
    url: url_ListAcceptedPortfolioShares_614002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBudgetsForResource_614019 = ref object of OpenApiRestCall_612658
proc url_ListBudgetsForResource_614021(protocol: Scheme; host: string; base: string;
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

proc validate_ListBudgetsForResource_614020(path: JsonNode; query: JsonNode;
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
  var valid_614022 = query.getOrDefault("PageToken")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "PageToken", valid_614022
  var valid_614023 = query.getOrDefault("PageSize")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "PageSize", valid_614023
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
  var valid_614024 = header.getOrDefault("X-Amz-Target")
  valid_614024 = validateParameter(valid_614024, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListBudgetsForResource"))
  if valid_614024 != nil:
    section.add "X-Amz-Target", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Signature")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Signature", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Content-Sha256", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Date")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Date", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-Credential")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Credential", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Security-Token")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Security-Token", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Algorithm")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Algorithm", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-SignedHeaders", valid_614031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614033: Call_ListBudgetsForResource_614019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the budgets associated to the specified resource.
  ## 
  let valid = call_614033.validator(path, query, header, formData, body)
  let scheme = call_614033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614033.url(scheme.get, call_614033.host, call_614033.base,
                         call_614033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614033, url, valid)

proc call*(call_614034: Call_ListBudgetsForResource_614019; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listBudgetsForResource
  ## Lists all the budgets associated to the specified resource.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614035 = newJObject()
  var body_614036 = newJObject()
  add(query_614035, "PageToken", newJString(PageToken))
  add(query_614035, "PageSize", newJString(PageSize))
  if body != nil:
    body_614036 = body
  result = call_614034.call(nil, query_614035, nil, nil, body_614036)

var listBudgetsForResource* = Call_ListBudgetsForResource_614019(
    name: "listBudgetsForResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource",
    validator: validate_ListBudgetsForResource_614020, base: "/",
    url: url_ListBudgetsForResource_614021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConstraintsForPortfolio_614037 = ref object of OpenApiRestCall_612658
proc url_ListConstraintsForPortfolio_614039(protocol: Scheme; host: string;
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

proc validate_ListConstraintsForPortfolio_614038(path: JsonNode; query: JsonNode;
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
  var valid_614040 = query.getOrDefault("PageToken")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "PageToken", valid_614040
  var valid_614041 = query.getOrDefault("PageSize")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "PageSize", valid_614041
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
  var valid_614042 = header.getOrDefault("X-Amz-Target")
  valid_614042 = validateParameter(valid_614042, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListConstraintsForPortfolio"))
  if valid_614042 != nil:
    section.add "X-Amz-Target", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Signature")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Signature", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Content-Sha256", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-Date")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-Date", valid_614045
  var valid_614046 = header.getOrDefault("X-Amz-Credential")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "X-Amz-Credential", valid_614046
  var valid_614047 = header.getOrDefault("X-Amz-Security-Token")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "X-Amz-Security-Token", valid_614047
  var valid_614048 = header.getOrDefault("X-Amz-Algorithm")
  valid_614048 = validateParameter(valid_614048, JString, required = false,
                                 default = nil)
  if valid_614048 != nil:
    section.add "X-Amz-Algorithm", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-SignedHeaders", valid_614049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614051: Call_ListConstraintsForPortfolio_614037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  let valid = call_614051.validator(path, query, header, formData, body)
  let scheme = call_614051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614051.url(scheme.get, call_614051.host, call_614051.base,
                         call_614051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614051, url, valid)

proc call*(call_614052: Call_ListConstraintsForPortfolio_614037; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listConstraintsForPortfolio
  ## Lists the constraints for the specified portfolio and product.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614053 = newJObject()
  var body_614054 = newJObject()
  add(query_614053, "PageToken", newJString(PageToken))
  add(query_614053, "PageSize", newJString(PageSize))
  if body != nil:
    body_614054 = body
  result = call_614052.call(nil, query_614053, nil, nil, body_614054)

var listConstraintsForPortfolio* = Call_ListConstraintsForPortfolio_614037(
    name: "listConstraintsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio",
    validator: validate_ListConstraintsForPortfolio_614038, base: "/",
    url: url_ListConstraintsForPortfolio_614039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLaunchPaths_614055 = ref object of OpenApiRestCall_612658
proc url_ListLaunchPaths_614057(protocol: Scheme; host: string; base: string;
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

proc validate_ListLaunchPaths_614056(path: JsonNode; query: JsonNode;
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
  var valid_614058 = query.getOrDefault("PageToken")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "PageToken", valid_614058
  var valid_614059 = query.getOrDefault("PageSize")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "PageSize", valid_614059
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
  var valid_614060 = header.getOrDefault("X-Amz-Target")
  valid_614060 = validateParameter(valid_614060, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListLaunchPaths"))
  if valid_614060 != nil:
    section.add "X-Amz-Target", valid_614060
  var valid_614061 = header.getOrDefault("X-Amz-Signature")
  valid_614061 = validateParameter(valid_614061, JString, required = false,
                                 default = nil)
  if valid_614061 != nil:
    section.add "X-Amz-Signature", valid_614061
  var valid_614062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614062 = validateParameter(valid_614062, JString, required = false,
                                 default = nil)
  if valid_614062 != nil:
    section.add "X-Amz-Content-Sha256", valid_614062
  var valid_614063 = header.getOrDefault("X-Amz-Date")
  valid_614063 = validateParameter(valid_614063, JString, required = false,
                                 default = nil)
  if valid_614063 != nil:
    section.add "X-Amz-Date", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-Credential")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Credential", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Security-Token")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Security-Token", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Algorithm")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Algorithm", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-SignedHeaders", valid_614067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614069: Call_ListLaunchPaths_614055; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  let valid = call_614069.validator(path, query, header, formData, body)
  let scheme = call_614069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614069.url(scheme.get, call_614069.host, call_614069.base,
                         call_614069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614069, url, valid)

proc call*(call_614070: Call_ListLaunchPaths_614055; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listLaunchPaths
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614071 = newJObject()
  var body_614072 = newJObject()
  add(query_614071, "PageToken", newJString(PageToken))
  add(query_614071, "PageSize", newJString(PageSize))
  if body != nil:
    body_614072 = body
  result = call_614070.call(nil, query_614071, nil, nil, body_614072)

var listLaunchPaths* = Call_ListLaunchPaths_614055(name: "listLaunchPaths",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths",
    validator: validate_ListLaunchPaths_614056, base: "/", url: url_ListLaunchPaths_614057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationPortfolioAccess_614073 = ref object of OpenApiRestCall_612658
proc url_ListOrganizationPortfolioAccess_614075(protocol: Scheme; host: string;
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

proc validate_ListOrganizationPortfolioAccess_614074(path: JsonNode;
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
  var valid_614076 = query.getOrDefault("PageToken")
  valid_614076 = validateParameter(valid_614076, JString, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "PageToken", valid_614076
  var valid_614077 = query.getOrDefault("PageSize")
  valid_614077 = validateParameter(valid_614077, JString, required = false,
                                 default = nil)
  if valid_614077 != nil:
    section.add "PageSize", valid_614077
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
  var valid_614078 = header.getOrDefault("X-Amz-Target")
  valid_614078 = validateParameter(valid_614078, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"))
  if valid_614078 != nil:
    section.add "X-Amz-Target", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-Signature")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-Signature", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-Content-Sha256", valid_614080
  var valid_614081 = header.getOrDefault("X-Amz-Date")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "X-Amz-Date", valid_614081
  var valid_614082 = header.getOrDefault("X-Amz-Credential")
  valid_614082 = validateParameter(valid_614082, JString, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "X-Amz-Credential", valid_614082
  var valid_614083 = header.getOrDefault("X-Amz-Security-Token")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "X-Amz-Security-Token", valid_614083
  var valid_614084 = header.getOrDefault("X-Amz-Algorithm")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "X-Amz-Algorithm", valid_614084
  var valid_614085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "X-Amz-SignedHeaders", valid_614085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614087: Call_ListOrganizationPortfolioAccess_614073;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  let valid = call_614087.validator(path, query, header, formData, body)
  let scheme = call_614087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614087.url(scheme.get, call_614087.host, call_614087.base,
                         call_614087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614087, url, valid)

proc call*(call_614088: Call_ListOrganizationPortfolioAccess_614073;
          body: JsonNode; PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listOrganizationPortfolioAccess
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614089 = newJObject()
  var body_614090 = newJObject()
  add(query_614089, "PageToken", newJString(PageToken))
  add(query_614089, "PageSize", newJString(PageSize))
  if body != nil:
    body_614090 = body
  result = call_614088.call(nil, query_614089, nil, nil, body_614090)

var listOrganizationPortfolioAccess* = Call_ListOrganizationPortfolioAccess_614073(
    name: "listOrganizationPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess",
    validator: validate_ListOrganizationPortfolioAccess_614074, base: "/",
    url: url_ListOrganizationPortfolioAccess_614075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolioAccess_614091 = ref object of OpenApiRestCall_612658
proc url_ListPortfolioAccess_614093(protocol: Scheme; host: string; base: string;
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

proc validate_ListPortfolioAccess_614092(path: JsonNode; query: JsonNode;
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
  var valid_614094 = header.getOrDefault("X-Amz-Target")
  valid_614094 = validateParameter(valid_614094, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolioAccess"))
  if valid_614094 != nil:
    section.add "X-Amz-Target", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-Signature")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-Signature", valid_614095
  var valid_614096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614096 = validateParameter(valid_614096, JString, required = false,
                                 default = nil)
  if valid_614096 != nil:
    section.add "X-Amz-Content-Sha256", valid_614096
  var valid_614097 = header.getOrDefault("X-Amz-Date")
  valid_614097 = validateParameter(valid_614097, JString, required = false,
                                 default = nil)
  if valid_614097 != nil:
    section.add "X-Amz-Date", valid_614097
  var valid_614098 = header.getOrDefault("X-Amz-Credential")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "X-Amz-Credential", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-Security-Token")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-Security-Token", valid_614099
  var valid_614100 = header.getOrDefault("X-Amz-Algorithm")
  valid_614100 = validateParameter(valid_614100, JString, required = false,
                                 default = nil)
  if valid_614100 != nil:
    section.add "X-Amz-Algorithm", valid_614100
  var valid_614101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614101 = validateParameter(valid_614101, JString, required = false,
                                 default = nil)
  if valid_614101 != nil:
    section.add "X-Amz-SignedHeaders", valid_614101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614103: Call_ListPortfolioAccess_614091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account IDs that have access to the specified portfolio.
  ## 
  let valid = call_614103.validator(path, query, header, formData, body)
  let scheme = call_614103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614103.url(scheme.get, call_614103.host, call_614103.base,
                         call_614103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614103, url, valid)

proc call*(call_614104: Call_ListPortfolioAccess_614091; body: JsonNode): Recallable =
  ## listPortfolioAccess
  ## Lists the account IDs that have access to the specified portfolio.
  ##   body: JObject (required)
  var body_614105 = newJObject()
  if body != nil:
    body_614105 = body
  result = call_614104.call(nil, nil, nil, nil, body_614105)

var listPortfolioAccess* = Call_ListPortfolioAccess_614091(
    name: "listPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess",
    validator: validate_ListPortfolioAccess_614092, base: "/",
    url: url_ListPortfolioAccess_614093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolios_614106 = ref object of OpenApiRestCall_612658
proc url_ListPortfolios_614108(protocol: Scheme; host: string; base: string;
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

proc validate_ListPortfolios_614107(path: JsonNode; query: JsonNode;
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
  var valid_614109 = query.getOrDefault("PageToken")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "PageToken", valid_614109
  var valid_614110 = query.getOrDefault("PageSize")
  valid_614110 = validateParameter(valid_614110, JString, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "PageSize", valid_614110
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
  var valid_614111 = header.getOrDefault("X-Amz-Target")
  valid_614111 = validateParameter(valid_614111, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolios"))
  if valid_614111 != nil:
    section.add "X-Amz-Target", valid_614111
  var valid_614112 = header.getOrDefault("X-Amz-Signature")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "X-Amz-Signature", valid_614112
  var valid_614113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "X-Amz-Content-Sha256", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Date")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Date", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-Credential")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-Credential", valid_614115
  var valid_614116 = header.getOrDefault("X-Amz-Security-Token")
  valid_614116 = validateParameter(valid_614116, JString, required = false,
                                 default = nil)
  if valid_614116 != nil:
    section.add "X-Amz-Security-Token", valid_614116
  var valid_614117 = header.getOrDefault("X-Amz-Algorithm")
  valid_614117 = validateParameter(valid_614117, JString, required = false,
                                 default = nil)
  if valid_614117 != nil:
    section.add "X-Amz-Algorithm", valid_614117
  var valid_614118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "X-Amz-SignedHeaders", valid_614118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614120: Call_ListPortfolios_614106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios in the catalog.
  ## 
  let valid = call_614120.validator(path, query, header, formData, body)
  let scheme = call_614120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614120.url(scheme.get, call_614120.host, call_614120.base,
                         call_614120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614120, url, valid)

proc call*(call_614121: Call_ListPortfolios_614106; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listPortfolios
  ## Lists all portfolios in the catalog.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614122 = newJObject()
  var body_614123 = newJObject()
  add(query_614122, "PageToken", newJString(PageToken))
  add(query_614122, "PageSize", newJString(PageSize))
  if body != nil:
    body_614123 = body
  result = call_614121.call(nil, query_614122, nil, nil, body_614123)

var listPortfolios* = Call_ListPortfolios_614106(name: "listPortfolios",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios",
    validator: validate_ListPortfolios_614107, base: "/", url: url_ListPortfolios_614108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfoliosForProduct_614124 = ref object of OpenApiRestCall_612658
proc url_ListPortfoliosForProduct_614126(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_ListPortfoliosForProduct_614125(path: JsonNode; query: JsonNode;
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
  var valid_614127 = query.getOrDefault("PageToken")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "PageToken", valid_614127
  var valid_614128 = query.getOrDefault("PageSize")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "PageSize", valid_614128
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
  var valid_614129 = header.getOrDefault("X-Amz-Target")
  valid_614129 = validateParameter(valid_614129, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfoliosForProduct"))
  if valid_614129 != nil:
    section.add "X-Amz-Target", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Signature")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Signature", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Content-Sha256", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-Date")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Date", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Credential")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Credential", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-Security-Token")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Security-Token", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-Algorithm")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-Algorithm", valid_614135
  var valid_614136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614136 = validateParameter(valid_614136, JString, required = false,
                                 default = nil)
  if valid_614136 != nil:
    section.add "X-Amz-SignedHeaders", valid_614136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614138: Call_ListPortfoliosForProduct_614124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  let valid = call_614138.validator(path, query, header, formData, body)
  let scheme = call_614138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614138.url(scheme.get, call_614138.host, call_614138.base,
                         call_614138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614138, url, valid)

proc call*(call_614139: Call_ListPortfoliosForProduct_614124; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listPortfoliosForProduct
  ## Lists all portfolios that the specified product is associated with.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614140 = newJObject()
  var body_614141 = newJObject()
  add(query_614140, "PageToken", newJString(PageToken))
  add(query_614140, "PageSize", newJString(PageSize))
  if body != nil:
    body_614141 = body
  result = call_614139.call(nil, query_614140, nil, nil, body_614141)

var listPortfoliosForProduct* = Call_ListPortfoliosForProduct_614124(
    name: "listPortfoliosForProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct",
    validator: validate_ListPortfoliosForProduct_614125, base: "/",
    url: url_ListPortfoliosForProduct_614126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipalsForPortfolio_614142 = ref object of OpenApiRestCall_612658
proc url_ListPrincipalsForPortfolio_614144(protocol: Scheme; host: string;
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

proc validate_ListPrincipalsForPortfolio_614143(path: JsonNode; query: JsonNode;
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
  var valid_614145 = query.getOrDefault("PageToken")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "PageToken", valid_614145
  var valid_614146 = query.getOrDefault("PageSize")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "PageSize", valid_614146
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
  var valid_614147 = header.getOrDefault("X-Amz-Target")
  valid_614147 = validateParameter(valid_614147, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPrincipalsForPortfolio"))
  if valid_614147 != nil:
    section.add "X-Amz-Target", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-Signature")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-Signature", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-Content-Sha256", valid_614149
  var valid_614150 = header.getOrDefault("X-Amz-Date")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-Date", valid_614150
  var valid_614151 = header.getOrDefault("X-Amz-Credential")
  valid_614151 = validateParameter(valid_614151, JString, required = false,
                                 default = nil)
  if valid_614151 != nil:
    section.add "X-Amz-Credential", valid_614151
  var valid_614152 = header.getOrDefault("X-Amz-Security-Token")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-Security-Token", valid_614152
  var valid_614153 = header.getOrDefault("X-Amz-Algorithm")
  valid_614153 = validateParameter(valid_614153, JString, required = false,
                                 default = nil)
  if valid_614153 != nil:
    section.add "X-Amz-Algorithm", valid_614153
  var valid_614154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614154 = validateParameter(valid_614154, JString, required = false,
                                 default = nil)
  if valid_614154 != nil:
    section.add "X-Amz-SignedHeaders", valid_614154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614156: Call_ListPrincipalsForPortfolio_614142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  let valid = call_614156.validator(path, query, header, formData, body)
  let scheme = call_614156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614156.url(scheme.get, call_614156.host, call_614156.base,
                         call_614156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614156, url, valid)

proc call*(call_614157: Call_ListPrincipalsForPortfolio_614142; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listPrincipalsForPortfolio
  ## Lists all principal ARNs associated with the specified portfolio.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614158 = newJObject()
  var body_614159 = newJObject()
  add(query_614158, "PageToken", newJString(PageToken))
  add(query_614158, "PageSize", newJString(PageSize))
  if body != nil:
    body_614159 = body
  result = call_614157.call(nil, query_614158, nil, nil, body_614159)

var listPrincipalsForPortfolio* = Call_ListPrincipalsForPortfolio_614142(
    name: "listPrincipalsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio",
    validator: validate_ListPrincipalsForPortfolio_614143, base: "/",
    url: url_ListPrincipalsForPortfolio_614144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedProductPlans_614160 = ref object of OpenApiRestCall_612658
proc url_ListProvisionedProductPlans_614162(protocol: Scheme; host: string;
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

proc validate_ListProvisionedProductPlans_614161(path: JsonNode; query: JsonNode;
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
  var valid_614163 = header.getOrDefault("X-Amz-Target")
  valid_614163 = validateParameter(valid_614163, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisionedProductPlans"))
  if valid_614163 != nil:
    section.add "X-Amz-Target", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Signature")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Signature", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Content-Sha256", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Date")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Date", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Credential")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Credential", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-Security-Token")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-Security-Token", valid_614168
  var valid_614169 = header.getOrDefault("X-Amz-Algorithm")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "X-Amz-Algorithm", valid_614169
  var valid_614170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614170 = validateParameter(valid_614170, JString, required = false,
                                 default = nil)
  if valid_614170 != nil:
    section.add "X-Amz-SignedHeaders", valid_614170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614172: Call_ListProvisionedProductPlans_614160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ## 
  let valid = call_614172.validator(path, query, header, formData, body)
  let scheme = call_614172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614172.url(scheme.get, call_614172.host, call_614172.base,
                         call_614172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614172, url, valid)

proc call*(call_614173: Call_ListProvisionedProductPlans_614160; body: JsonNode): Recallable =
  ## listProvisionedProductPlans
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ##   body: JObject (required)
  var body_614174 = newJObject()
  if body != nil:
    body_614174 = body
  result = call_614173.call(nil, nil, nil, nil, body_614174)

var listProvisionedProductPlans* = Call_ListProvisionedProductPlans_614160(
    name: "listProvisionedProductPlans", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans",
    validator: validate_ListProvisionedProductPlans_614161, base: "/",
    url: url_ListProvisionedProductPlans_614162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifacts_614175 = ref object of OpenApiRestCall_612658
proc url_ListProvisioningArtifacts_614177(protocol: Scheme; host: string;
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

proc validate_ListProvisioningArtifacts_614176(path: JsonNode; query: JsonNode;
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
  var valid_614178 = header.getOrDefault("X-Amz-Target")
  valid_614178 = validateParameter(valid_614178, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifacts"))
  if valid_614178 != nil:
    section.add "X-Amz-Target", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Signature")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Signature", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Content-Sha256", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Date")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Date", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Credential")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Credential", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Security-Token")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Security-Token", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-Algorithm")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-Algorithm", valid_614184
  var valid_614185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-SignedHeaders", valid_614185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614187: Call_ListProvisioningArtifacts_614175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ## 
  let valid = call_614187.validator(path, query, header, formData, body)
  let scheme = call_614187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614187.url(scheme.get, call_614187.host, call_614187.base,
                         call_614187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614187, url, valid)

proc call*(call_614188: Call_ListProvisioningArtifacts_614175; body: JsonNode): Recallable =
  ## listProvisioningArtifacts
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ##   body: JObject (required)
  var body_614189 = newJObject()
  if body != nil:
    body_614189 = body
  result = call_614188.call(nil, nil, nil, nil, body_614189)

var listProvisioningArtifacts* = Call_ListProvisioningArtifacts_614175(
    name: "listProvisioningArtifacts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts",
    validator: validate_ListProvisioningArtifacts_614176, base: "/",
    url: url_ListProvisioningArtifacts_614177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifactsForServiceAction_614190 = ref object of OpenApiRestCall_612658
proc url_ListProvisioningArtifactsForServiceAction_614192(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisioningArtifactsForServiceAction_614191(path: JsonNode;
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
  var valid_614193 = query.getOrDefault("PageToken")
  valid_614193 = validateParameter(valid_614193, JString, required = false,
                                 default = nil)
  if valid_614193 != nil:
    section.add "PageToken", valid_614193
  var valid_614194 = query.getOrDefault("PageSize")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "PageSize", valid_614194
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
  var valid_614195 = header.getOrDefault("X-Amz-Target")
  valid_614195 = validateParameter(valid_614195, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"))
  if valid_614195 != nil:
    section.add "X-Amz-Target", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-Signature")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-Signature", valid_614196
  var valid_614197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Content-Sha256", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Date")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Date", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Credential")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Credential", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-Security-Token")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-Security-Token", valid_614200
  var valid_614201 = header.getOrDefault("X-Amz-Algorithm")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "X-Amz-Algorithm", valid_614201
  var valid_614202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614202 = validateParameter(valid_614202, JString, required = false,
                                 default = nil)
  if valid_614202 != nil:
    section.add "X-Amz-SignedHeaders", valid_614202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614204: Call_ListProvisioningArtifactsForServiceAction_614190;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  let valid = call_614204.validator(path, query, header, formData, body)
  let scheme = call_614204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614204.url(scheme.get, call_614204.host, call_614204.base,
                         call_614204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614204, url, valid)

proc call*(call_614205: Call_ListProvisioningArtifactsForServiceAction_614190;
          body: JsonNode; PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listProvisioningArtifactsForServiceAction
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614206 = newJObject()
  var body_614207 = newJObject()
  add(query_614206, "PageToken", newJString(PageToken))
  add(query_614206, "PageSize", newJString(PageSize))
  if body != nil:
    body_614207 = body
  result = call_614205.call(nil, query_614206, nil, nil, body_614207)

var listProvisioningArtifactsForServiceAction* = Call_ListProvisioningArtifactsForServiceAction_614190(
    name: "listProvisioningArtifactsForServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction",
    validator: validate_ListProvisioningArtifactsForServiceAction_614191,
    base: "/", url: url_ListProvisioningArtifactsForServiceAction_614192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecordHistory_614208 = ref object of OpenApiRestCall_612658
proc url_ListRecordHistory_614210(protocol: Scheme; host: string; base: string;
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

proc validate_ListRecordHistory_614209(path: JsonNode; query: JsonNode;
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
  var valid_614211 = header.getOrDefault("X-Amz-Target")
  valid_614211 = validateParameter(valid_614211, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListRecordHistory"))
  if valid_614211 != nil:
    section.add "X-Amz-Target", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-Signature")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-Signature", valid_614212
  var valid_614213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-Content-Sha256", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Date")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Date", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-Credential")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-Credential", valid_614215
  var valid_614216 = header.getOrDefault("X-Amz-Security-Token")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-Security-Token", valid_614216
  var valid_614217 = header.getOrDefault("X-Amz-Algorithm")
  valid_614217 = validateParameter(valid_614217, JString, required = false,
                                 default = nil)
  if valid_614217 != nil:
    section.add "X-Amz-Algorithm", valid_614217
  var valid_614218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "X-Amz-SignedHeaders", valid_614218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614220: Call_ListRecordHistory_614208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified requests or all performed requests.
  ## 
  let valid = call_614220.validator(path, query, header, formData, body)
  let scheme = call_614220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614220.url(scheme.get, call_614220.host, call_614220.base,
                         call_614220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614220, url, valid)

proc call*(call_614221: Call_ListRecordHistory_614208; body: JsonNode): Recallable =
  ## listRecordHistory
  ## Lists the specified requests or all performed requests.
  ##   body: JObject (required)
  var body_614222 = newJObject()
  if body != nil:
    body_614222 = body
  result = call_614221.call(nil, nil, nil, nil, body_614222)

var listRecordHistory* = Call_ListRecordHistory_614208(name: "listRecordHistory",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory",
    validator: validate_ListRecordHistory_614209, base: "/",
    url: url_ListRecordHistory_614210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForTagOption_614223 = ref object of OpenApiRestCall_612658
proc url_ListResourcesForTagOption_614225(protocol: Scheme; host: string;
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

proc validate_ListResourcesForTagOption_614224(path: JsonNode; query: JsonNode;
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
  var valid_614226 = query.getOrDefault("PageToken")
  valid_614226 = validateParameter(valid_614226, JString, required = false,
                                 default = nil)
  if valid_614226 != nil:
    section.add "PageToken", valid_614226
  var valid_614227 = query.getOrDefault("PageSize")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "PageSize", valid_614227
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
  var valid_614228 = header.getOrDefault("X-Amz-Target")
  valid_614228 = validateParameter(valid_614228, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListResourcesForTagOption"))
  if valid_614228 != nil:
    section.add "X-Amz-Target", valid_614228
  var valid_614229 = header.getOrDefault("X-Amz-Signature")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "X-Amz-Signature", valid_614229
  var valid_614230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "X-Amz-Content-Sha256", valid_614230
  var valid_614231 = header.getOrDefault("X-Amz-Date")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "X-Amz-Date", valid_614231
  var valid_614232 = header.getOrDefault("X-Amz-Credential")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "X-Amz-Credential", valid_614232
  var valid_614233 = header.getOrDefault("X-Amz-Security-Token")
  valid_614233 = validateParameter(valid_614233, JString, required = false,
                                 default = nil)
  if valid_614233 != nil:
    section.add "X-Amz-Security-Token", valid_614233
  var valid_614234 = header.getOrDefault("X-Amz-Algorithm")
  valid_614234 = validateParameter(valid_614234, JString, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "X-Amz-Algorithm", valid_614234
  var valid_614235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614235 = validateParameter(valid_614235, JString, required = false,
                                 default = nil)
  if valid_614235 != nil:
    section.add "X-Amz-SignedHeaders", valid_614235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614237: Call_ListResourcesForTagOption_614223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources associated with the specified TagOption.
  ## 
  let valid = call_614237.validator(path, query, header, formData, body)
  let scheme = call_614237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614237.url(scheme.get, call_614237.host, call_614237.base,
                         call_614237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614237, url, valid)

proc call*(call_614238: Call_ListResourcesForTagOption_614223; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listResourcesForTagOption
  ## Lists the resources associated with the specified TagOption.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614239 = newJObject()
  var body_614240 = newJObject()
  add(query_614239, "PageToken", newJString(PageToken))
  add(query_614239, "PageSize", newJString(PageSize))
  if body != nil:
    body_614240 = body
  result = call_614238.call(nil, query_614239, nil, nil, body_614240)

var listResourcesForTagOption* = Call_ListResourcesForTagOption_614223(
    name: "listResourcesForTagOption", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption",
    validator: validate_ListResourcesForTagOption_614224, base: "/",
    url: url_ListResourcesForTagOption_614225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActions_614241 = ref object of OpenApiRestCall_612658
proc url_ListServiceActions_614243(protocol: Scheme; host: string; base: string;
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

proc validate_ListServiceActions_614242(path: JsonNode; query: JsonNode;
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
  var valid_614244 = query.getOrDefault("PageToken")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "PageToken", valid_614244
  var valid_614245 = query.getOrDefault("PageSize")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "PageSize", valid_614245
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
  var valid_614246 = header.getOrDefault("X-Amz-Target")
  valid_614246 = validateParameter(valid_614246, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActions"))
  if valid_614246 != nil:
    section.add "X-Amz-Target", valid_614246
  var valid_614247 = header.getOrDefault("X-Amz-Signature")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "X-Amz-Signature", valid_614247
  var valid_614248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614248 = validateParameter(valid_614248, JString, required = false,
                                 default = nil)
  if valid_614248 != nil:
    section.add "X-Amz-Content-Sha256", valid_614248
  var valid_614249 = header.getOrDefault("X-Amz-Date")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "X-Amz-Date", valid_614249
  var valid_614250 = header.getOrDefault("X-Amz-Credential")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "X-Amz-Credential", valid_614250
  var valid_614251 = header.getOrDefault("X-Amz-Security-Token")
  valid_614251 = validateParameter(valid_614251, JString, required = false,
                                 default = nil)
  if valid_614251 != nil:
    section.add "X-Amz-Security-Token", valid_614251
  var valid_614252 = header.getOrDefault("X-Amz-Algorithm")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "X-Amz-Algorithm", valid_614252
  var valid_614253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "X-Amz-SignedHeaders", valid_614253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614255: Call_ListServiceActions_614241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all self-service actions.
  ## 
  let valid = call_614255.validator(path, query, header, formData, body)
  let scheme = call_614255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614255.url(scheme.get, call_614255.host, call_614255.base,
                         call_614255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614255, url, valid)

proc call*(call_614256: Call_ListServiceActions_614241; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listServiceActions
  ## Lists all self-service actions.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614257 = newJObject()
  var body_614258 = newJObject()
  add(query_614257, "PageToken", newJString(PageToken))
  add(query_614257, "PageSize", newJString(PageSize))
  if body != nil:
    body_614258 = body
  result = call_614256.call(nil, query_614257, nil, nil, body_614258)

var listServiceActions* = Call_ListServiceActions_614241(
    name: "listServiceActions", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions",
    validator: validate_ListServiceActions_614242, base: "/",
    url: url_ListServiceActions_614243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActionsForProvisioningArtifact_614259 = ref object of OpenApiRestCall_612658
proc url_ListServiceActionsForProvisioningArtifact_614261(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceActionsForProvisioningArtifact_614260(path: JsonNode;
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
  var valid_614262 = query.getOrDefault("PageToken")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "PageToken", valid_614262
  var valid_614263 = query.getOrDefault("PageSize")
  valid_614263 = validateParameter(valid_614263, JString, required = false,
                                 default = nil)
  if valid_614263 != nil:
    section.add "PageSize", valid_614263
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
  var valid_614264 = header.getOrDefault("X-Amz-Target")
  valid_614264 = validateParameter(valid_614264, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"))
  if valid_614264 != nil:
    section.add "X-Amz-Target", valid_614264
  var valid_614265 = header.getOrDefault("X-Amz-Signature")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "X-Amz-Signature", valid_614265
  var valid_614266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-Content-Sha256", valid_614266
  var valid_614267 = header.getOrDefault("X-Amz-Date")
  valid_614267 = validateParameter(valid_614267, JString, required = false,
                                 default = nil)
  if valid_614267 != nil:
    section.add "X-Amz-Date", valid_614267
  var valid_614268 = header.getOrDefault("X-Amz-Credential")
  valid_614268 = validateParameter(valid_614268, JString, required = false,
                                 default = nil)
  if valid_614268 != nil:
    section.add "X-Amz-Credential", valid_614268
  var valid_614269 = header.getOrDefault("X-Amz-Security-Token")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Security-Token", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-Algorithm")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-Algorithm", valid_614270
  var valid_614271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-SignedHeaders", valid_614271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614273: Call_ListServiceActionsForProvisioningArtifact_614259;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  let valid = call_614273.validator(path, query, header, formData, body)
  let scheme = call_614273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614273.url(scheme.get, call_614273.host, call_614273.base,
                         call_614273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614273, url, valid)

proc call*(call_614274: Call_ListServiceActionsForProvisioningArtifact_614259;
          body: JsonNode; PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listServiceActionsForProvisioningArtifact
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614275 = newJObject()
  var body_614276 = newJObject()
  add(query_614275, "PageToken", newJString(PageToken))
  add(query_614275, "PageSize", newJString(PageSize))
  if body != nil:
    body_614276 = body
  result = call_614274.call(nil, query_614275, nil, nil, body_614276)

var listServiceActionsForProvisioningArtifact* = Call_ListServiceActionsForProvisioningArtifact_614259(
    name: "listServiceActionsForProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact",
    validator: validate_ListServiceActionsForProvisioningArtifact_614260,
    base: "/", url: url_ListServiceActionsForProvisioningArtifact_614261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStackInstancesForProvisionedProduct_614277 = ref object of OpenApiRestCall_612658
proc url_ListStackInstancesForProvisionedProduct_614279(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStackInstancesForProvisionedProduct_614278(path: JsonNode;
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
  var valid_614280 = header.getOrDefault("X-Amz-Target")
  valid_614280 = validateParameter(valid_614280, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"))
  if valid_614280 != nil:
    section.add "X-Amz-Target", valid_614280
  var valid_614281 = header.getOrDefault("X-Amz-Signature")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "X-Amz-Signature", valid_614281
  var valid_614282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614282 = validateParameter(valid_614282, JString, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "X-Amz-Content-Sha256", valid_614282
  var valid_614283 = header.getOrDefault("X-Amz-Date")
  valid_614283 = validateParameter(valid_614283, JString, required = false,
                                 default = nil)
  if valid_614283 != nil:
    section.add "X-Amz-Date", valid_614283
  var valid_614284 = header.getOrDefault("X-Amz-Credential")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "X-Amz-Credential", valid_614284
  var valid_614285 = header.getOrDefault("X-Amz-Security-Token")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "X-Amz-Security-Token", valid_614285
  var valid_614286 = header.getOrDefault("X-Amz-Algorithm")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "X-Amz-Algorithm", valid_614286
  var valid_614287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "X-Amz-SignedHeaders", valid_614287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614289: Call_ListStackInstancesForProvisionedProduct_614277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ## 
  let valid = call_614289.validator(path, query, header, formData, body)
  let scheme = call_614289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614289.url(scheme.get, call_614289.host, call_614289.base,
                         call_614289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614289, url, valid)

proc call*(call_614290: Call_ListStackInstancesForProvisionedProduct_614277;
          body: JsonNode): Recallable =
  ## listStackInstancesForProvisionedProduct
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ##   body: JObject (required)
  var body_614291 = newJObject()
  if body != nil:
    body_614291 = body
  result = call_614290.call(nil, nil, nil, nil, body_614291)

var listStackInstancesForProvisionedProduct* = Call_ListStackInstancesForProvisionedProduct_614277(
    name: "listStackInstancesForProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct",
    validator: validate_ListStackInstancesForProvisionedProduct_614278, base: "/",
    url: url_ListStackInstancesForProvisionedProduct_614279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagOptions_614292 = ref object of OpenApiRestCall_612658
proc url_ListTagOptions_614294(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagOptions_614293(path: JsonNode; query: JsonNode;
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
  var valid_614295 = query.getOrDefault("PageToken")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "PageToken", valid_614295
  var valid_614296 = query.getOrDefault("PageSize")
  valid_614296 = validateParameter(valid_614296, JString, required = false,
                                 default = nil)
  if valid_614296 != nil:
    section.add "PageSize", valid_614296
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
  var valid_614297 = header.getOrDefault("X-Amz-Target")
  valid_614297 = validateParameter(valid_614297, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListTagOptions"))
  if valid_614297 != nil:
    section.add "X-Amz-Target", valid_614297
  var valid_614298 = header.getOrDefault("X-Amz-Signature")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-Signature", valid_614298
  var valid_614299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614299 = validateParameter(valid_614299, JString, required = false,
                                 default = nil)
  if valid_614299 != nil:
    section.add "X-Amz-Content-Sha256", valid_614299
  var valid_614300 = header.getOrDefault("X-Amz-Date")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-Date", valid_614300
  var valid_614301 = header.getOrDefault("X-Amz-Credential")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Credential", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-Security-Token")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-Security-Token", valid_614302
  var valid_614303 = header.getOrDefault("X-Amz-Algorithm")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-Algorithm", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-SignedHeaders", valid_614304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614306: Call_ListTagOptions_614292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  let valid = call_614306.validator(path, query, header, formData, body)
  let scheme = call_614306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614306.url(scheme.get, call_614306.host, call_614306.base,
                         call_614306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614306, url, valid)

proc call*(call_614307: Call_ListTagOptions_614292; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listTagOptions
  ## Lists the specified TagOptions or all TagOptions.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614308 = newJObject()
  var body_614309 = newJObject()
  add(query_614308, "PageToken", newJString(PageToken))
  add(query_614308, "PageSize", newJString(PageSize))
  if body != nil:
    body_614309 = body
  result = call_614307.call(nil, query_614308, nil, nil, body_614309)

var listTagOptions* = Call_ListTagOptions_614292(name: "listTagOptions",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions",
    validator: validate_ListTagOptions_614293, base: "/", url: url_ListTagOptions_614294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ProvisionProduct_614310 = ref object of OpenApiRestCall_612658
proc url_ProvisionProduct_614312(protocol: Scheme; host: string; base: string;
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

proc validate_ProvisionProduct_614311(path: JsonNode; query: JsonNode;
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
  var valid_614313 = header.getOrDefault("X-Amz-Target")
  valid_614313 = validateParameter(valid_614313, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ProvisionProduct"))
  if valid_614313 != nil:
    section.add "X-Amz-Target", valid_614313
  var valid_614314 = header.getOrDefault("X-Amz-Signature")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "X-Amz-Signature", valid_614314
  var valid_614315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "X-Amz-Content-Sha256", valid_614315
  var valid_614316 = header.getOrDefault("X-Amz-Date")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Date", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-Credential")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-Credential", valid_614317
  var valid_614318 = header.getOrDefault("X-Amz-Security-Token")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "X-Amz-Security-Token", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Algorithm")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Algorithm", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-SignedHeaders", valid_614320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614322: Call_ProvisionProduct_614310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ## 
  let valid = call_614322.validator(path, query, header, formData, body)
  let scheme = call_614322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614322.url(scheme.get, call_614322.host, call_614322.base,
                         call_614322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614322, url, valid)

proc call*(call_614323: Call_ProvisionProduct_614310; body: JsonNode): Recallable =
  ## provisionProduct
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ##   body: JObject (required)
  var body_614324 = newJObject()
  if body != nil:
    body_614324 = body
  result = call_614323.call(nil, nil, nil, nil, body_614324)

var provisionProduct* = Call_ProvisionProduct_614310(name: "provisionProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct",
    validator: validate_ProvisionProduct_614311, base: "/",
    url: url_ProvisionProduct_614312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectPortfolioShare_614325 = ref object of OpenApiRestCall_612658
proc url_RejectPortfolioShare_614327(protocol: Scheme; host: string; base: string;
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

proc validate_RejectPortfolioShare_614326(path: JsonNode; query: JsonNode;
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
  var valid_614328 = header.getOrDefault("X-Amz-Target")
  valid_614328 = validateParameter(valid_614328, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.RejectPortfolioShare"))
  if valid_614328 != nil:
    section.add "X-Amz-Target", valid_614328
  var valid_614329 = header.getOrDefault("X-Amz-Signature")
  valid_614329 = validateParameter(valid_614329, JString, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "X-Amz-Signature", valid_614329
  var valid_614330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614330 = validateParameter(valid_614330, JString, required = false,
                                 default = nil)
  if valid_614330 != nil:
    section.add "X-Amz-Content-Sha256", valid_614330
  var valid_614331 = header.getOrDefault("X-Amz-Date")
  valid_614331 = validateParameter(valid_614331, JString, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "X-Amz-Date", valid_614331
  var valid_614332 = header.getOrDefault("X-Amz-Credential")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-Credential", valid_614332
  var valid_614333 = header.getOrDefault("X-Amz-Security-Token")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Security-Token", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Algorithm")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Algorithm", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-SignedHeaders", valid_614335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614337: Call_RejectPortfolioShare_614325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an offer to share the specified portfolio.
  ## 
  let valid = call_614337.validator(path, query, header, formData, body)
  let scheme = call_614337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614337.url(scheme.get, call_614337.host, call_614337.base,
                         call_614337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614337, url, valid)

proc call*(call_614338: Call_RejectPortfolioShare_614325; body: JsonNode): Recallable =
  ## rejectPortfolioShare
  ## Rejects an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_614339 = newJObject()
  if body != nil:
    body_614339 = body
  result = call_614338.call(nil, nil, nil, nil, body_614339)

var rejectPortfolioShare* = Call_RejectPortfolioShare_614325(
    name: "rejectPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare",
    validator: validate_RejectPortfolioShare_614326, base: "/",
    url: url_RejectPortfolioShare_614327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScanProvisionedProducts_614340 = ref object of OpenApiRestCall_612658
proc url_ScanProvisionedProducts_614342(protocol: Scheme; host: string; base: string;
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

proc validate_ScanProvisionedProducts_614341(path: JsonNode; query: JsonNode;
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
  var valid_614343 = header.getOrDefault("X-Amz-Target")
  valid_614343 = validateParameter(valid_614343, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ScanProvisionedProducts"))
  if valid_614343 != nil:
    section.add "X-Amz-Target", valid_614343
  var valid_614344 = header.getOrDefault("X-Amz-Signature")
  valid_614344 = validateParameter(valid_614344, JString, required = false,
                                 default = nil)
  if valid_614344 != nil:
    section.add "X-Amz-Signature", valid_614344
  var valid_614345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614345 = validateParameter(valid_614345, JString, required = false,
                                 default = nil)
  if valid_614345 != nil:
    section.add "X-Amz-Content-Sha256", valid_614345
  var valid_614346 = header.getOrDefault("X-Amz-Date")
  valid_614346 = validateParameter(valid_614346, JString, required = false,
                                 default = nil)
  if valid_614346 != nil:
    section.add "X-Amz-Date", valid_614346
  var valid_614347 = header.getOrDefault("X-Amz-Credential")
  valid_614347 = validateParameter(valid_614347, JString, required = false,
                                 default = nil)
  if valid_614347 != nil:
    section.add "X-Amz-Credential", valid_614347
  var valid_614348 = header.getOrDefault("X-Amz-Security-Token")
  valid_614348 = validateParameter(valid_614348, JString, required = false,
                                 default = nil)
  if valid_614348 != nil:
    section.add "X-Amz-Security-Token", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Algorithm")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Algorithm", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-SignedHeaders", valid_614350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614352: Call_ScanProvisionedProducts_614340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ## 
  let valid = call_614352.validator(path, query, header, formData, body)
  let scheme = call_614352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614352.url(scheme.get, call_614352.host, call_614352.base,
                         call_614352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614352, url, valid)

proc call*(call_614353: Call_ScanProvisionedProducts_614340; body: JsonNode): Recallable =
  ## scanProvisionedProducts
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ##   body: JObject (required)
  var body_614354 = newJObject()
  if body != nil:
    body_614354 = body
  result = call_614353.call(nil, nil, nil, nil, body_614354)

var scanProvisionedProducts* = Call_ScanProvisionedProducts_614340(
    name: "scanProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts",
    validator: validate_ScanProvisionedProducts_614341, base: "/",
    url: url_ScanProvisionedProducts_614342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProducts_614355 = ref object of OpenApiRestCall_612658
proc url_SearchProducts_614357(protocol: Scheme; host: string; base: string;
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

proc validate_SearchProducts_614356(path: JsonNode; query: JsonNode;
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
  var valid_614358 = query.getOrDefault("PageToken")
  valid_614358 = validateParameter(valid_614358, JString, required = false,
                                 default = nil)
  if valid_614358 != nil:
    section.add "PageToken", valid_614358
  var valid_614359 = query.getOrDefault("PageSize")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "PageSize", valid_614359
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
  var valid_614360 = header.getOrDefault("X-Amz-Target")
  valid_614360 = validateParameter(valid_614360, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProducts"))
  if valid_614360 != nil:
    section.add "X-Amz-Target", valid_614360
  var valid_614361 = header.getOrDefault("X-Amz-Signature")
  valid_614361 = validateParameter(valid_614361, JString, required = false,
                                 default = nil)
  if valid_614361 != nil:
    section.add "X-Amz-Signature", valid_614361
  var valid_614362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614362 = validateParameter(valid_614362, JString, required = false,
                                 default = nil)
  if valid_614362 != nil:
    section.add "X-Amz-Content-Sha256", valid_614362
  var valid_614363 = header.getOrDefault("X-Amz-Date")
  valid_614363 = validateParameter(valid_614363, JString, required = false,
                                 default = nil)
  if valid_614363 != nil:
    section.add "X-Amz-Date", valid_614363
  var valid_614364 = header.getOrDefault("X-Amz-Credential")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "X-Amz-Credential", valid_614364
  var valid_614365 = header.getOrDefault("X-Amz-Security-Token")
  valid_614365 = validateParameter(valid_614365, JString, required = false,
                                 default = nil)
  if valid_614365 != nil:
    section.add "X-Amz-Security-Token", valid_614365
  var valid_614366 = header.getOrDefault("X-Amz-Algorithm")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "X-Amz-Algorithm", valid_614366
  var valid_614367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-SignedHeaders", valid_614367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614369: Call_SearchProducts_614355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products to which the caller has access.
  ## 
  let valid = call_614369.validator(path, query, header, formData, body)
  let scheme = call_614369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614369.url(scheme.get, call_614369.host, call_614369.base,
                         call_614369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614369, url, valid)

proc call*(call_614370: Call_SearchProducts_614355; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## searchProducts
  ## Gets information about the products to which the caller has access.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614371 = newJObject()
  var body_614372 = newJObject()
  add(query_614371, "PageToken", newJString(PageToken))
  add(query_614371, "PageSize", newJString(PageSize))
  if body != nil:
    body_614372 = body
  result = call_614370.call(nil, query_614371, nil, nil, body_614372)

var searchProducts* = Call_SearchProducts_614355(name: "searchProducts",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts",
    validator: validate_SearchProducts_614356, base: "/", url: url_SearchProducts_614357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProductsAsAdmin_614373 = ref object of OpenApiRestCall_612658
proc url_SearchProductsAsAdmin_614375(protocol: Scheme; host: string; base: string;
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

proc validate_SearchProductsAsAdmin_614374(path: JsonNode; query: JsonNode;
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
  var valid_614376 = query.getOrDefault("PageToken")
  valid_614376 = validateParameter(valid_614376, JString, required = false,
                                 default = nil)
  if valid_614376 != nil:
    section.add "PageToken", valid_614376
  var valid_614377 = query.getOrDefault("PageSize")
  valid_614377 = validateParameter(valid_614377, JString, required = false,
                                 default = nil)
  if valid_614377 != nil:
    section.add "PageSize", valid_614377
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
  var valid_614378 = header.getOrDefault("X-Amz-Target")
  valid_614378 = validateParameter(valid_614378, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProductsAsAdmin"))
  if valid_614378 != nil:
    section.add "X-Amz-Target", valid_614378
  var valid_614379 = header.getOrDefault("X-Amz-Signature")
  valid_614379 = validateParameter(valid_614379, JString, required = false,
                                 default = nil)
  if valid_614379 != nil:
    section.add "X-Amz-Signature", valid_614379
  var valid_614380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614380 = validateParameter(valid_614380, JString, required = false,
                                 default = nil)
  if valid_614380 != nil:
    section.add "X-Amz-Content-Sha256", valid_614380
  var valid_614381 = header.getOrDefault("X-Amz-Date")
  valid_614381 = validateParameter(valid_614381, JString, required = false,
                                 default = nil)
  if valid_614381 != nil:
    section.add "X-Amz-Date", valid_614381
  var valid_614382 = header.getOrDefault("X-Amz-Credential")
  valid_614382 = validateParameter(valid_614382, JString, required = false,
                                 default = nil)
  if valid_614382 != nil:
    section.add "X-Amz-Credential", valid_614382
  var valid_614383 = header.getOrDefault("X-Amz-Security-Token")
  valid_614383 = validateParameter(valid_614383, JString, required = false,
                                 default = nil)
  if valid_614383 != nil:
    section.add "X-Amz-Security-Token", valid_614383
  var valid_614384 = header.getOrDefault("X-Amz-Algorithm")
  valid_614384 = validateParameter(valid_614384, JString, required = false,
                                 default = nil)
  if valid_614384 != nil:
    section.add "X-Amz-Algorithm", valid_614384
  var valid_614385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-SignedHeaders", valid_614385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614387: Call_SearchProductsAsAdmin_614373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  let valid = call_614387.validator(path, query, header, formData, body)
  let scheme = call_614387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614387.url(scheme.get, call_614387.host, call_614387.base,
                         call_614387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614387, url, valid)

proc call*(call_614388: Call_SearchProductsAsAdmin_614373; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## searchProductsAsAdmin
  ## Gets information about the products for the specified portfolio or all products.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614389 = newJObject()
  var body_614390 = newJObject()
  add(query_614389, "PageToken", newJString(PageToken))
  add(query_614389, "PageSize", newJString(PageSize))
  if body != nil:
    body_614390 = body
  result = call_614388.call(nil, query_614389, nil, nil, body_614390)

var searchProductsAsAdmin* = Call_SearchProductsAsAdmin_614373(
    name: "searchProductsAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin",
    validator: validate_SearchProductsAsAdmin_614374, base: "/",
    url: url_SearchProductsAsAdmin_614375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProvisionedProducts_614391 = ref object of OpenApiRestCall_612658
proc url_SearchProvisionedProducts_614393(protocol: Scheme; host: string;
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

proc validate_SearchProvisionedProducts_614392(path: JsonNode; query: JsonNode;
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
  var valid_614394 = query.getOrDefault("PageToken")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "PageToken", valid_614394
  var valid_614395 = query.getOrDefault("PageSize")
  valid_614395 = validateParameter(valid_614395, JString, required = false,
                                 default = nil)
  if valid_614395 != nil:
    section.add "PageSize", valid_614395
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
  var valid_614396 = header.getOrDefault("X-Amz-Target")
  valid_614396 = validateParameter(valid_614396, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProvisionedProducts"))
  if valid_614396 != nil:
    section.add "X-Amz-Target", valid_614396
  var valid_614397 = header.getOrDefault("X-Amz-Signature")
  valid_614397 = validateParameter(valid_614397, JString, required = false,
                                 default = nil)
  if valid_614397 != nil:
    section.add "X-Amz-Signature", valid_614397
  var valid_614398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614398 = validateParameter(valid_614398, JString, required = false,
                                 default = nil)
  if valid_614398 != nil:
    section.add "X-Amz-Content-Sha256", valid_614398
  var valid_614399 = header.getOrDefault("X-Amz-Date")
  valid_614399 = validateParameter(valid_614399, JString, required = false,
                                 default = nil)
  if valid_614399 != nil:
    section.add "X-Amz-Date", valid_614399
  var valid_614400 = header.getOrDefault("X-Amz-Credential")
  valid_614400 = validateParameter(valid_614400, JString, required = false,
                                 default = nil)
  if valid_614400 != nil:
    section.add "X-Amz-Credential", valid_614400
  var valid_614401 = header.getOrDefault("X-Amz-Security-Token")
  valid_614401 = validateParameter(valid_614401, JString, required = false,
                                 default = nil)
  if valid_614401 != nil:
    section.add "X-Amz-Security-Token", valid_614401
  var valid_614402 = header.getOrDefault("X-Amz-Algorithm")
  valid_614402 = validateParameter(valid_614402, JString, required = false,
                                 default = nil)
  if valid_614402 != nil:
    section.add "X-Amz-Algorithm", valid_614402
  var valid_614403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614403 = validateParameter(valid_614403, JString, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "X-Amz-SignedHeaders", valid_614403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614405: Call_SearchProvisionedProducts_614391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  let valid = call_614405.validator(path, query, header, formData, body)
  let scheme = call_614405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614405.url(scheme.get, call_614405.host, call_614405.base,
                         call_614405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614405, url, valid)

proc call*(call_614406: Call_SearchProvisionedProducts_614391; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## searchProvisionedProducts
  ## Gets information about the provisioned products that meet the specified criteria.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_614407 = newJObject()
  var body_614408 = newJObject()
  add(query_614407, "PageToken", newJString(PageToken))
  add(query_614407, "PageSize", newJString(PageSize))
  if body != nil:
    body_614408 = body
  result = call_614406.call(nil, query_614407, nil, nil, body_614408)

var searchProvisionedProducts* = Call_SearchProvisionedProducts_614391(
    name: "searchProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts",
    validator: validate_SearchProvisionedProducts_614392, base: "/",
    url: url_SearchProvisionedProducts_614393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateProvisionedProduct_614409 = ref object of OpenApiRestCall_612658
proc url_TerminateProvisionedProduct_614411(protocol: Scheme; host: string;
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

proc validate_TerminateProvisionedProduct_614410(path: JsonNode; query: JsonNode;
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
  var valid_614412 = header.getOrDefault("X-Amz-Target")
  valid_614412 = validateParameter(valid_614412, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.TerminateProvisionedProduct"))
  if valid_614412 != nil:
    section.add "X-Amz-Target", valid_614412
  var valid_614413 = header.getOrDefault("X-Amz-Signature")
  valid_614413 = validateParameter(valid_614413, JString, required = false,
                                 default = nil)
  if valid_614413 != nil:
    section.add "X-Amz-Signature", valid_614413
  var valid_614414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614414 = validateParameter(valid_614414, JString, required = false,
                                 default = nil)
  if valid_614414 != nil:
    section.add "X-Amz-Content-Sha256", valid_614414
  var valid_614415 = header.getOrDefault("X-Amz-Date")
  valid_614415 = validateParameter(valid_614415, JString, required = false,
                                 default = nil)
  if valid_614415 != nil:
    section.add "X-Amz-Date", valid_614415
  var valid_614416 = header.getOrDefault("X-Amz-Credential")
  valid_614416 = validateParameter(valid_614416, JString, required = false,
                                 default = nil)
  if valid_614416 != nil:
    section.add "X-Amz-Credential", valid_614416
  var valid_614417 = header.getOrDefault("X-Amz-Security-Token")
  valid_614417 = validateParameter(valid_614417, JString, required = false,
                                 default = nil)
  if valid_614417 != nil:
    section.add "X-Amz-Security-Token", valid_614417
  var valid_614418 = header.getOrDefault("X-Amz-Algorithm")
  valid_614418 = validateParameter(valid_614418, JString, required = false,
                                 default = nil)
  if valid_614418 != nil:
    section.add "X-Amz-Algorithm", valid_614418
  var valid_614419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614419 = validateParameter(valid_614419, JString, required = false,
                                 default = nil)
  if valid_614419 != nil:
    section.add "X-Amz-SignedHeaders", valid_614419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614421: Call_TerminateProvisionedProduct_614409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_614421.validator(path, query, header, formData, body)
  let scheme = call_614421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614421.url(scheme.get, call_614421.host, call_614421.base,
                         call_614421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614421, url, valid)

proc call*(call_614422: Call_TerminateProvisionedProduct_614409; body: JsonNode): Recallable =
  ## terminateProvisionedProduct
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_614423 = newJObject()
  if body != nil:
    body_614423 = body
  result = call_614422.call(nil, nil, nil, nil, body_614423)

var terminateProvisionedProduct* = Call_TerminateProvisionedProduct_614409(
    name: "terminateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct",
    validator: validate_TerminateProvisionedProduct_614410, base: "/",
    url: url_TerminateProvisionedProduct_614411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConstraint_614424 = ref object of OpenApiRestCall_612658
proc url_UpdateConstraint_614426(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConstraint_614425(path: JsonNode; query: JsonNode;
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
  var valid_614427 = header.getOrDefault("X-Amz-Target")
  valid_614427 = validateParameter(valid_614427, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateConstraint"))
  if valid_614427 != nil:
    section.add "X-Amz-Target", valid_614427
  var valid_614428 = header.getOrDefault("X-Amz-Signature")
  valid_614428 = validateParameter(valid_614428, JString, required = false,
                                 default = nil)
  if valid_614428 != nil:
    section.add "X-Amz-Signature", valid_614428
  var valid_614429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614429 = validateParameter(valid_614429, JString, required = false,
                                 default = nil)
  if valid_614429 != nil:
    section.add "X-Amz-Content-Sha256", valid_614429
  var valid_614430 = header.getOrDefault("X-Amz-Date")
  valid_614430 = validateParameter(valid_614430, JString, required = false,
                                 default = nil)
  if valid_614430 != nil:
    section.add "X-Amz-Date", valid_614430
  var valid_614431 = header.getOrDefault("X-Amz-Credential")
  valid_614431 = validateParameter(valid_614431, JString, required = false,
                                 default = nil)
  if valid_614431 != nil:
    section.add "X-Amz-Credential", valid_614431
  var valid_614432 = header.getOrDefault("X-Amz-Security-Token")
  valid_614432 = validateParameter(valid_614432, JString, required = false,
                                 default = nil)
  if valid_614432 != nil:
    section.add "X-Amz-Security-Token", valid_614432
  var valid_614433 = header.getOrDefault("X-Amz-Algorithm")
  valid_614433 = validateParameter(valid_614433, JString, required = false,
                                 default = nil)
  if valid_614433 != nil:
    section.add "X-Amz-Algorithm", valid_614433
  var valid_614434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614434 = validateParameter(valid_614434, JString, required = false,
                                 default = nil)
  if valid_614434 != nil:
    section.add "X-Amz-SignedHeaders", valid_614434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614436: Call_UpdateConstraint_614424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified constraint.
  ## 
  let valid = call_614436.validator(path, query, header, formData, body)
  let scheme = call_614436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614436.url(scheme.get, call_614436.host, call_614436.base,
                         call_614436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614436, url, valid)

proc call*(call_614437: Call_UpdateConstraint_614424; body: JsonNode): Recallable =
  ## updateConstraint
  ## Updates the specified constraint.
  ##   body: JObject (required)
  var body_614438 = newJObject()
  if body != nil:
    body_614438 = body
  result = call_614437.call(nil, nil, nil, nil, body_614438)

var updateConstraint* = Call_UpdateConstraint_614424(name: "updateConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint",
    validator: validate_UpdateConstraint_614425, base: "/",
    url: url_UpdateConstraint_614426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePortfolio_614439 = ref object of OpenApiRestCall_612658
proc url_UpdatePortfolio_614441(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePortfolio_614440(path: JsonNode; query: JsonNode;
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
  var valid_614442 = header.getOrDefault("X-Amz-Target")
  valid_614442 = validateParameter(valid_614442, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdatePortfolio"))
  if valid_614442 != nil:
    section.add "X-Amz-Target", valid_614442
  var valid_614443 = header.getOrDefault("X-Amz-Signature")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "X-Amz-Signature", valid_614443
  var valid_614444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614444 = validateParameter(valid_614444, JString, required = false,
                                 default = nil)
  if valid_614444 != nil:
    section.add "X-Amz-Content-Sha256", valid_614444
  var valid_614445 = header.getOrDefault("X-Amz-Date")
  valid_614445 = validateParameter(valid_614445, JString, required = false,
                                 default = nil)
  if valid_614445 != nil:
    section.add "X-Amz-Date", valid_614445
  var valid_614446 = header.getOrDefault("X-Amz-Credential")
  valid_614446 = validateParameter(valid_614446, JString, required = false,
                                 default = nil)
  if valid_614446 != nil:
    section.add "X-Amz-Credential", valid_614446
  var valid_614447 = header.getOrDefault("X-Amz-Security-Token")
  valid_614447 = validateParameter(valid_614447, JString, required = false,
                                 default = nil)
  if valid_614447 != nil:
    section.add "X-Amz-Security-Token", valid_614447
  var valid_614448 = header.getOrDefault("X-Amz-Algorithm")
  valid_614448 = validateParameter(valid_614448, JString, required = false,
                                 default = nil)
  if valid_614448 != nil:
    section.add "X-Amz-Algorithm", valid_614448
  var valid_614449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614449 = validateParameter(valid_614449, JString, required = false,
                                 default = nil)
  if valid_614449 != nil:
    section.add "X-Amz-SignedHeaders", valid_614449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614451: Call_UpdatePortfolio_614439; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ## 
  let valid = call_614451.validator(path, query, header, formData, body)
  let scheme = call_614451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614451.url(scheme.get, call_614451.host, call_614451.base,
                         call_614451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614451, url, valid)

proc call*(call_614452: Call_UpdatePortfolio_614439; body: JsonNode): Recallable =
  ## updatePortfolio
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_614453 = newJObject()
  if body != nil:
    body_614453 = body
  result = call_614452.call(nil, nil, nil, nil, body_614453)

var updatePortfolio* = Call_UpdatePortfolio_614439(name: "updatePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio",
    validator: validate_UpdatePortfolio_614440, base: "/", url: url_UpdatePortfolio_614441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProduct_614454 = ref object of OpenApiRestCall_612658
proc url_UpdateProduct_614456(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProduct_614455(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614457 = header.getOrDefault("X-Amz-Target")
  valid_614457 = validateParameter(valid_614457, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProduct"))
  if valid_614457 != nil:
    section.add "X-Amz-Target", valid_614457
  var valid_614458 = header.getOrDefault("X-Amz-Signature")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-Signature", valid_614458
  var valid_614459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614459 = validateParameter(valid_614459, JString, required = false,
                                 default = nil)
  if valid_614459 != nil:
    section.add "X-Amz-Content-Sha256", valid_614459
  var valid_614460 = header.getOrDefault("X-Amz-Date")
  valid_614460 = validateParameter(valid_614460, JString, required = false,
                                 default = nil)
  if valid_614460 != nil:
    section.add "X-Amz-Date", valid_614460
  var valid_614461 = header.getOrDefault("X-Amz-Credential")
  valid_614461 = validateParameter(valid_614461, JString, required = false,
                                 default = nil)
  if valid_614461 != nil:
    section.add "X-Amz-Credential", valid_614461
  var valid_614462 = header.getOrDefault("X-Amz-Security-Token")
  valid_614462 = validateParameter(valid_614462, JString, required = false,
                                 default = nil)
  if valid_614462 != nil:
    section.add "X-Amz-Security-Token", valid_614462
  var valid_614463 = header.getOrDefault("X-Amz-Algorithm")
  valid_614463 = validateParameter(valid_614463, JString, required = false,
                                 default = nil)
  if valid_614463 != nil:
    section.add "X-Amz-Algorithm", valid_614463
  var valid_614464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614464 = validateParameter(valid_614464, JString, required = false,
                                 default = nil)
  if valid_614464 != nil:
    section.add "X-Amz-SignedHeaders", valid_614464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614466: Call_UpdateProduct_614454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified product.
  ## 
  let valid = call_614466.validator(path, query, header, formData, body)
  let scheme = call_614466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614466.url(scheme.get, call_614466.host, call_614466.base,
                         call_614466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614466, url, valid)

proc call*(call_614467: Call_UpdateProduct_614454; body: JsonNode): Recallable =
  ## updateProduct
  ## Updates the specified product.
  ##   body: JObject (required)
  var body_614468 = newJObject()
  if body != nil:
    body_614468 = body
  result = call_614467.call(nil, nil, nil, nil, body_614468)

var updateProduct* = Call_UpdateProduct_614454(name: "updateProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct",
    validator: validate_UpdateProduct_614455, base: "/", url: url_UpdateProduct_614456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProduct_614469 = ref object of OpenApiRestCall_612658
proc url_UpdateProvisionedProduct_614471(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_UpdateProvisionedProduct_614470(path: JsonNode; query: JsonNode;
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
  var valid_614472 = header.getOrDefault("X-Amz-Target")
  valid_614472 = validateParameter(valid_614472, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProduct"))
  if valid_614472 != nil:
    section.add "X-Amz-Target", valid_614472
  var valid_614473 = header.getOrDefault("X-Amz-Signature")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Signature", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Content-Sha256", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-Date")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-Date", valid_614475
  var valid_614476 = header.getOrDefault("X-Amz-Credential")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "X-Amz-Credential", valid_614476
  var valid_614477 = header.getOrDefault("X-Amz-Security-Token")
  valid_614477 = validateParameter(valid_614477, JString, required = false,
                                 default = nil)
  if valid_614477 != nil:
    section.add "X-Amz-Security-Token", valid_614477
  var valid_614478 = header.getOrDefault("X-Amz-Algorithm")
  valid_614478 = validateParameter(valid_614478, JString, required = false,
                                 default = nil)
  if valid_614478 != nil:
    section.add "X-Amz-Algorithm", valid_614478
  var valid_614479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614479 = validateParameter(valid_614479, JString, required = false,
                                 default = nil)
  if valid_614479 != nil:
    section.add "X-Amz-SignedHeaders", valid_614479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614481: Call_UpdateProvisionedProduct_614469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_614481.validator(path, query, header, formData, body)
  let scheme = call_614481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614481.url(scheme.get, call_614481.host, call_614481.base,
                         call_614481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614481, url, valid)

proc call*(call_614482: Call_UpdateProvisionedProduct_614469; body: JsonNode): Recallable =
  ## updateProvisionedProduct
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_614483 = newJObject()
  if body != nil:
    body_614483 = body
  result = call_614482.call(nil, nil, nil, nil, body_614483)

var updateProvisionedProduct* = Call_UpdateProvisionedProduct_614469(
    name: "updateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct",
    validator: validate_UpdateProvisionedProduct_614470, base: "/",
    url: url_UpdateProvisionedProduct_614471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProductProperties_614484 = ref object of OpenApiRestCall_612658
proc url_UpdateProvisionedProductProperties_614486(protocol: Scheme; host: string;
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

proc validate_UpdateProvisionedProductProperties_614485(path: JsonNode;
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
  var valid_614487 = header.getOrDefault("X-Amz-Target")
  valid_614487 = validateParameter(valid_614487, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProductProperties"))
  if valid_614487 != nil:
    section.add "X-Amz-Target", valid_614487
  var valid_614488 = header.getOrDefault("X-Amz-Signature")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "X-Amz-Signature", valid_614488
  var valid_614489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-Content-Sha256", valid_614489
  var valid_614490 = header.getOrDefault("X-Amz-Date")
  valid_614490 = validateParameter(valid_614490, JString, required = false,
                                 default = nil)
  if valid_614490 != nil:
    section.add "X-Amz-Date", valid_614490
  var valid_614491 = header.getOrDefault("X-Amz-Credential")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-Credential", valid_614491
  var valid_614492 = header.getOrDefault("X-Amz-Security-Token")
  valid_614492 = validateParameter(valid_614492, JString, required = false,
                                 default = nil)
  if valid_614492 != nil:
    section.add "X-Amz-Security-Token", valid_614492
  var valid_614493 = header.getOrDefault("X-Amz-Algorithm")
  valid_614493 = validateParameter(valid_614493, JString, required = false,
                                 default = nil)
  if valid_614493 != nil:
    section.add "X-Amz-Algorithm", valid_614493
  var valid_614494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614494 = validateParameter(valid_614494, JString, required = false,
                                 default = nil)
  if valid_614494 != nil:
    section.add "X-Amz-SignedHeaders", valid_614494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614496: Call_UpdateProvisionedProductProperties_614484;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests updates to the properties of the specified provisioned product.
  ## 
  let valid = call_614496.validator(path, query, header, formData, body)
  let scheme = call_614496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614496.url(scheme.get, call_614496.host, call_614496.base,
                         call_614496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614496, url, valid)

proc call*(call_614497: Call_UpdateProvisionedProductProperties_614484;
          body: JsonNode): Recallable =
  ## updateProvisionedProductProperties
  ## Requests updates to the properties of the specified provisioned product.
  ##   body: JObject (required)
  var body_614498 = newJObject()
  if body != nil:
    body_614498 = body
  result = call_614497.call(nil, nil, nil, nil, body_614498)

var updateProvisionedProductProperties* = Call_UpdateProvisionedProductProperties_614484(
    name: "updateProvisionedProductProperties", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties",
    validator: validate_UpdateProvisionedProductProperties_614485, base: "/",
    url: url_UpdateProvisionedProductProperties_614486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisioningArtifact_614499 = ref object of OpenApiRestCall_612658
proc url_UpdateProvisioningArtifact_614501(protocol: Scheme; host: string;
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

proc validate_UpdateProvisioningArtifact_614500(path: JsonNode; query: JsonNode;
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
  var valid_614502 = header.getOrDefault("X-Amz-Target")
  valid_614502 = validateParameter(valid_614502, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisioningArtifact"))
  if valid_614502 != nil:
    section.add "X-Amz-Target", valid_614502
  var valid_614503 = header.getOrDefault("X-Amz-Signature")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "X-Amz-Signature", valid_614503
  var valid_614504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614504 = validateParameter(valid_614504, JString, required = false,
                                 default = nil)
  if valid_614504 != nil:
    section.add "X-Amz-Content-Sha256", valid_614504
  var valid_614505 = header.getOrDefault("X-Amz-Date")
  valid_614505 = validateParameter(valid_614505, JString, required = false,
                                 default = nil)
  if valid_614505 != nil:
    section.add "X-Amz-Date", valid_614505
  var valid_614506 = header.getOrDefault("X-Amz-Credential")
  valid_614506 = validateParameter(valid_614506, JString, required = false,
                                 default = nil)
  if valid_614506 != nil:
    section.add "X-Amz-Credential", valid_614506
  var valid_614507 = header.getOrDefault("X-Amz-Security-Token")
  valid_614507 = validateParameter(valid_614507, JString, required = false,
                                 default = nil)
  if valid_614507 != nil:
    section.add "X-Amz-Security-Token", valid_614507
  var valid_614508 = header.getOrDefault("X-Amz-Algorithm")
  valid_614508 = validateParameter(valid_614508, JString, required = false,
                                 default = nil)
  if valid_614508 != nil:
    section.add "X-Amz-Algorithm", valid_614508
  var valid_614509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-SignedHeaders", valid_614509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614511: Call_UpdateProvisioningArtifact_614499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_614511.validator(path, query, header, formData, body)
  let scheme = call_614511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614511.url(scheme.get, call_614511.host, call_614511.base,
                         call_614511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614511, url, valid)

proc call*(call_614512: Call_UpdateProvisioningArtifact_614499; body: JsonNode): Recallable =
  ## updateProvisioningArtifact
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_614513 = newJObject()
  if body != nil:
    body_614513 = body
  result = call_614512.call(nil, nil, nil, nil, body_614513)

var updateProvisioningArtifact* = Call_UpdateProvisioningArtifact_614499(
    name: "updateProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact",
    validator: validate_UpdateProvisioningArtifact_614500, base: "/",
    url: url_UpdateProvisioningArtifact_614501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceAction_614514 = ref object of OpenApiRestCall_612658
proc url_UpdateServiceAction_614516(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateServiceAction_614515(path: JsonNode; query: JsonNode;
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
  var valid_614517 = header.getOrDefault("X-Amz-Target")
  valid_614517 = validateParameter(valid_614517, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateServiceAction"))
  if valid_614517 != nil:
    section.add "X-Amz-Target", valid_614517
  var valid_614518 = header.getOrDefault("X-Amz-Signature")
  valid_614518 = validateParameter(valid_614518, JString, required = false,
                                 default = nil)
  if valid_614518 != nil:
    section.add "X-Amz-Signature", valid_614518
  var valid_614519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614519 = validateParameter(valid_614519, JString, required = false,
                                 default = nil)
  if valid_614519 != nil:
    section.add "X-Amz-Content-Sha256", valid_614519
  var valid_614520 = header.getOrDefault("X-Amz-Date")
  valid_614520 = validateParameter(valid_614520, JString, required = false,
                                 default = nil)
  if valid_614520 != nil:
    section.add "X-Amz-Date", valid_614520
  var valid_614521 = header.getOrDefault("X-Amz-Credential")
  valid_614521 = validateParameter(valid_614521, JString, required = false,
                                 default = nil)
  if valid_614521 != nil:
    section.add "X-Amz-Credential", valid_614521
  var valid_614522 = header.getOrDefault("X-Amz-Security-Token")
  valid_614522 = validateParameter(valid_614522, JString, required = false,
                                 default = nil)
  if valid_614522 != nil:
    section.add "X-Amz-Security-Token", valid_614522
  var valid_614523 = header.getOrDefault("X-Amz-Algorithm")
  valid_614523 = validateParameter(valid_614523, JString, required = false,
                                 default = nil)
  if valid_614523 != nil:
    section.add "X-Amz-Algorithm", valid_614523
  var valid_614524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614524 = validateParameter(valid_614524, JString, required = false,
                                 default = nil)
  if valid_614524 != nil:
    section.add "X-Amz-SignedHeaders", valid_614524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614526: Call_UpdateServiceAction_614514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a self-service action.
  ## 
  let valid = call_614526.validator(path, query, header, formData, body)
  let scheme = call_614526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614526.url(scheme.get, call_614526.host, call_614526.base,
                         call_614526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614526, url, valid)

proc call*(call_614527: Call_UpdateServiceAction_614514; body: JsonNode): Recallable =
  ## updateServiceAction
  ## Updates a self-service action.
  ##   body: JObject (required)
  var body_614528 = newJObject()
  if body != nil:
    body_614528 = body
  result = call_614527.call(nil, nil, nil, nil, body_614528)

var updateServiceAction* = Call_UpdateServiceAction_614514(
    name: "updateServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction",
    validator: validate_UpdateServiceAction_614515, base: "/",
    url: url_UpdateServiceAction_614516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagOption_614529 = ref object of OpenApiRestCall_612658
proc url_UpdateTagOption_614531(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTagOption_614530(path: JsonNode; query: JsonNode;
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
  var valid_614532 = header.getOrDefault("X-Amz-Target")
  valid_614532 = validateParameter(valid_614532, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateTagOption"))
  if valid_614532 != nil:
    section.add "X-Amz-Target", valid_614532
  var valid_614533 = header.getOrDefault("X-Amz-Signature")
  valid_614533 = validateParameter(valid_614533, JString, required = false,
                                 default = nil)
  if valid_614533 != nil:
    section.add "X-Amz-Signature", valid_614533
  var valid_614534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614534 = validateParameter(valid_614534, JString, required = false,
                                 default = nil)
  if valid_614534 != nil:
    section.add "X-Amz-Content-Sha256", valid_614534
  var valid_614535 = header.getOrDefault("X-Amz-Date")
  valid_614535 = validateParameter(valid_614535, JString, required = false,
                                 default = nil)
  if valid_614535 != nil:
    section.add "X-Amz-Date", valid_614535
  var valid_614536 = header.getOrDefault("X-Amz-Credential")
  valid_614536 = validateParameter(valid_614536, JString, required = false,
                                 default = nil)
  if valid_614536 != nil:
    section.add "X-Amz-Credential", valid_614536
  var valid_614537 = header.getOrDefault("X-Amz-Security-Token")
  valid_614537 = validateParameter(valid_614537, JString, required = false,
                                 default = nil)
  if valid_614537 != nil:
    section.add "X-Amz-Security-Token", valid_614537
  var valid_614538 = header.getOrDefault("X-Amz-Algorithm")
  valid_614538 = validateParameter(valid_614538, JString, required = false,
                                 default = nil)
  if valid_614538 != nil:
    section.add "X-Amz-Algorithm", valid_614538
  var valid_614539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "X-Amz-SignedHeaders", valid_614539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614541: Call_UpdateTagOption_614529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified TagOption.
  ## 
  let valid = call_614541.validator(path, query, header, formData, body)
  let scheme = call_614541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614541.url(scheme.get, call_614541.host, call_614541.base,
                         call_614541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614541, url, valid)

proc call*(call_614542: Call_UpdateTagOption_614529; body: JsonNode): Recallable =
  ## updateTagOption
  ## Updates the specified TagOption.
  ##   body: JObject (required)
  var body_614543 = newJObject()
  if body != nil:
    body_614543 = body
  result = call_614542.call(nil, nil, nil, nil, body_614543)

var updateTagOption* = Call_UpdateTagOption_614529(name: "updateTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption",
    validator: validate_UpdateTagOption_614530, base: "/", url: url_UpdateTagOption_614531,
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
