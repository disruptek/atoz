
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

  OpenApiRestCall_615866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_615866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_615866): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "servicecatalog.ap-northeast-1.amazonaws.com", "ap-southeast-1": "servicecatalog.ap-southeast-1.amazonaws.com", "us-west-2": "servicecatalog.us-west-2.amazonaws.com", "eu-west-2": "servicecatalog.eu-west-2.amazonaws.com", "ap-northeast-3": "servicecatalog.ap-northeast-3.amazonaws.com", "eu-central-1": "servicecatalog.eu-central-1.amazonaws.com", "us-east-2": "servicecatalog.us-east-2.amazonaws.com", "us-east-1": "servicecatalog.us-east-1.amazonaws.com", "cn-northwest-1": "servicecatalog.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "servicecatalog.ap-northeast-2.amazonaws.com", "ap-south-1": "servicecatalog.ap-south-1.amazonaws.com", "eu-north-1": "servicecatalog.eu-north-1.amazonaws.com", "us-west-1": "servicecatalog.us-west-1.amazonaws.com", "us-gov-east-1": "servicecatalog.us-gov-east-1.amazonaws.com", "eu-west-3": "servicecatalog.eu-west-3.amazonaws.com", "cn-north-1": "servicecatalog.cn-north-1.amazonaws.com.cn", "sa-east-1": "servicecatalog.sa-east-1.amazonaws.com", "eu-west-1": "servicecatalog.eu-west-1.amazonaws.com", "us-gov-west-1": "servicecatalog.us-gov-west-1.amazonaws.com", "ap-southeast-2": "servicecatalog.ap-southeast-2.amazonaws.com", "ca-central-1": "servicecatalog.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "servicecatalog.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "servicecatalog.ap-southeast-1.amazonaws.com",
      "us-west-2": "servicecatalog.us-west-2.amazonaws.com",
      "eu-west-2": "servicecatalog.eu-west-2.amazonaws.com",
      "ap-northeast-3": "servicecatalog.ap-northeast-3.amazonaws.com",
      "eu-central-1": "servicecatalog.eu-central-1.amazonaws.com",
      "us-east-2": "servicecatalog.us-east-2.amazonaws.com",
      "us-east-1": "servicecatalog.us-east-1.amazonaws.com",
      "cn-northwest-1": "servicecatalog.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "servicecatalog.ap-northeast-2.amazonaws.com",
      "ap-south-1": "servicecatalog.ap-south-1.amazonaws.com",
      "eu-north-1": "servicecatalog.eu-north-1.amazonaws.com",
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
  Call_AcceptPortfolioShare_616205 = ref object of OpenApiRestCall_615866
proc url_AcceptPortfolioShare_616207(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptPortfolioShare_616206(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616319 = header.getOrDefault("X-Amz-Date")
  valid_616319 = validateParameter(valid_616319, JString, required = false,
                                 default = nil)
  if valid_616319 != nil:
    section.add "X-Amz-Date", valid_616319
  var valid_616320 = header.getOrDefault("X-Amz-Security-Token")
  valid_616320 = validateParameter(valid_616320, JString, required = false,
                                 default = nil)
  if valid_616320 != nil:
    section.add "X-Amz-Security-Token", valid_616320
  var valid_616321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616321 = validateParameter(valid_616321, JString, required = false,
                                 default = nil)
  if valid_616321 != nil:
    section.add "X-Amz-Content-Sha256", valid_616321
  var valid_616322 = header.getOrDefault("X-Amz-Algorithm")
  valid_616322 = validateParameter(valid_616322, JString, required = false,
                                 default = nil)
  if valid_616322 != nil:
    section.add "X-Amz-Algorithm", valid_616322
  var valid_616323 = header.getOrDefault("X-Amz-Signature")
  valid_616323 = validateParameter(valid_616323, JString, required = false,
                                 default = nil)
  if valid_616323 != nil:
    section.add "X-Amz-Signature", valid_616323
  var valid_616324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616324 = validateParameter(valid_616324, JString, required = false,
                                 default = nil)
  if valid_616324 != nil:
    section.add "X-Amz-SignedHeaders", valid_616324
  var valid_616338 = header.getOrDefault("X-Amz-Target")
  valid_616338 = validateParameter(valid_616338, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AcceptPortfolioShare"))
  if valid_616338 != nil:
    section.add "X-Amz-Target", valid_616338
  var valid_616339 = header.getOrDefault("X-Amz-Credential")
  valid_616339 = validateParameter(valid_616339, JString, required = false,
                                 default = nil)
  if valid_616339 != nil:
    section.add "X-Amz-Credential", valid_616339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616363: Call_AcceptPortfolioShare_616205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an offer to share the specified portfolio.
  ## 
  let valid = call_616363.validator(path, query, header, formData, body)
  let scheme = call_616363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616363.url(scheme.get, call_616363.host, call_616363.base,
                         call_616363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616363, url, valid)

proc call*(call_616434: Call_AcceptPortfolioShare_616205; body: JsonNode): Recallable =
  ## acceptPortfolioShare
  ## Accepts an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_616435 = newJObject()
  if body != nil:
    body_616435 = body
  result = call_616434.call(nil, nil, nil, nil, body_616435)

var acceptPortfolioShare* = Call_AcceptPortfolioShare_616205(
    name: "acceptPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare",
    validator: validate_AcceptPortfolioShare_616206, base: "/",
    url: url_AcceptPortfolioShare_616207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateBudgetWithResource_616476 = ref object of OpenApiRestCall_615866
proc url_AssociateBudgetWithResource_616478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateBudgetWithResource_616477(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616479 = header.getOrDefault("X-Amz-Date")
  valid_616479 = validateParameter(valid_616479, JString, required = false,
                                 default = nil)
  if valid_616479 != nil:
    section.add "X-Amz-Date", valid_616479
  var valid_616480 = header.getOrDefault("X-Amz-Security-Token")
  valid_616480 = validateParameter(valid_616480, JString, required = false,
                                 default = nil)
  if valid_616480 != nil:
    section.add "X-Amz-Security-Token", valid_616480
  var valid_616481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616481 = validateParameter(valid_616481, JString, required = false,
                                 default = nil)
  if valid_616481 != nil:
    section.add "X-Amz-Content-Sha256", valid_616481
  var valid_616482 = header.getOrDefault("X-Amz-Algorithm")
  valid_616482 = validateParameter(valid_616482, JString, required = false,
                                 default = nil)
  if valid_616482 != nil:
    section.add "X-Amz-Algorithm", valid_616482
  var valid_616483 = header.getOrDefault("X-Amz-Signature")
  valid_616483 = validateParameter(valid_616483, JString, required = false,
                                 default = nil)
  if valid_616483 != nil:
    section.add "X-Amz-Signature", valid_616483
  var valid_616484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616484 = validateParameter(valid_616484, JString, required = false,
                                 default = nil)
  if valid_616484 != nil:
    section.add "X-Amz-SignedHeaders", valid_616484
  var valid_616485 = header.getOrDefault("X-Amz-Target")
  valid_616485 = validateParameter(valid_616485, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateBudgetWithResource"))
  if valid_616485 != nil:
    section.add "X-Amz-Target", valid_616485
  var valid_616486 = header.getOrDefault("X-Amz-Credential")
  valid_616486 = validateParameter(valid_616486, JString, required = false,
                                 default = nil)
  if valid_616486 != nil:
    section.add "X-Amz-Credential", valid_616486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616488: Call_AssociateBudgetWithResource_616476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified budget with the specified resource.
  ## 
  let valid = call_616488.validator(path, query, header, formData, body)
  let scheme = call_616488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616488.url(scheme.get, call_616488.host, call_616488.base,
                         call_616488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616488, url, valid)

proc call*(call_616489: Call_AssociateBudgetWithResource_616476; body: JsonNode): Recallable =
  ## associateBudgetWithResource
  ## Associates the specified budget with the specified resource.
  ##   body: JObject (required)
  var body_616490 = newJObject()
  if body != nil:
    body_616490 = body
  result = call_616489.call(nil, nil, nil, nil, body_616490)

var associateBudgetWithResource* = Call_AssociateBudgetWithResource_616476(
    name: "associateBudgetWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource",
    validator: validate_AssociateBudgetWithResource_616477, base: "/",
    url: url_AssociateBudgetWithResource_616478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePrincipalWithPortfolio_616491 = ref object of OpenApiRestCall_615866
proc url_AssociatePrincipalWithPortfolio_616493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociatePrincipalWithPortfolio_616492(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616494 = header.getOrDefault("X-Amz-Date")
  valid_616494 = validateParameter(valid_616494, JString, required = false,
                                 default = nil)
  if valid_616494 != nil:
    section.add "X-Amz-Date", valid_616494
  var valid_616495 = header.getOrDefault("X-Amz-Security-Token")
  valid_616495 = validateParameter(valid_616495, JString, required = false,
                                 default = nil)
  if valid_616495 != nil:
    section.add "X-Amz-Security-Token", valid_616495
  var valid_616496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616496 = validateParameter(valid_616496, JString, required = false,
                                 default = nil)
  if valid_616496 != nil:
    section.add "X-Amz-Content-Sha256", valid_616496
  var valid_616497 = header.getOrDefault("X-Amz-Algorithm")
  valid_616497 = validateParameter(valid_616497, JString, required = false,
                                 default = nil)
  if valid_616497 != nil:
    section.add "X-Amz-Algorithm", valid_616497
  var valid_616498 = header.getOrDefault("X-Amz-Signature")
  valid_616498 = validateParameter(valid_616498, JString, required = false,
                                 default = nil)
  if valid_616498 != nil:
    section.add "X-Amz-Signature", valid_616498
  var valid_616499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616499 = validateParameter(valid_616499, JString, required = false,
                                 default = nil)
  if valid_616499 != nil:
    section.add "X-Amz-SignedHeaders", valid_616499
  var valid_616500 = header.getOrDefault("X-Amz-Target")
  valid_616500 = validateParameter(valid_616500, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"))
  if valid_616500 != nil:
    section.add "X-Amz-Target", valid_616500
  var valid_616501 = header.getOrDefault("X-Amz-Credential")
  valid_616501 = validateParameter(valid_616501, JString, required = false,
                                 default = nil)
  if valid_616501 != nil:
    section.add "X-Amz-Credential", valid_616501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616503: Call_AssociatePrincipalWithPortfolio_616491;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified principal ARN with the specified portfolio.
  ## 
  let valid = call_616503.validator(path, query, header, formData, body)
  let scheme = call_616503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616503.url(scheme.get, call_616503.host, call_616503.base,
                         call_616503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616503, url, valid)

proc call*(call_616504: Call_AssociatePrincipalWithPortfolio_616491; body: JsonNode): Recallable =
  ## associatePrincipalWithPortfolio
  ## Associates the specified principal ARN with the specified portfolio.
  ##   body: JObject (required)
  var body_616505 = newJObject()
  if body != nil:
    body_616505 = body
  result = call_616504.call(nil, nil, nil, nil, body_616505)

var associatePrincipalWithPortfolio* = Call_AssociatePrincipalWithPortfolio_616491(
    name: "associatePrincipalWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio",
    validator: validate_AssociatePrincipalWithPortfolio_616492, base: "/",
    url: url_AssociatePrincipalWithPortfolio_616493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateProductWithPortfolio_616506 = ref object of OpenApiRestCall_615866
proc url_AssociateProductWithPortfolio_616508(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateProductWithPortfolio_616507(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616509 = header.getOrDefault("X-Amz-Date")
  valid_616509 = validateParameter(valid_616509, JString, required = false,
                                 default = nil)
  if valid_616509 != nil:
    section.add "X-Amz-Date", valid_616509
  var valid_616510 = header.getOrDefault("X-Amz-Security-Token")
  valid_616510 = validateParameter(valid_616510, JString, required = false,
                                 default = nil)
  if valid_616510 != nil:
    section.add "X-Amz-Security-Token", valid_616510
  var valid_616511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616511 = validateParameter(valid_616511, JString, required = false,
                                 default = nil)
  if valid_616511 != nil:
    section.add "X-Amz-Content-Sha256", valid_616511
  var valid_616512 = header.getOrDefault("X-Amz-Algorithm")
  valid_616512 = validateParameter(valid_616512, JString, required = false,
                                 default = nil)
  if valid_616512 != nil:
    section.add "X-Amz-Algorithm", valid_616512
  var valid_616513 = header.getOrDefault("X-Amz-Signature")
  valid_616513 = validateParameter(valid_616513, JString, required = false,
                                 default = nil)
  if valid_616513 != nil:
    section.add "X-Amz-Signature", valid_616513
  var valid_616514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616514 = validateParameter(valid_616514, JString, required = false,
                                 default = nil)
  if valid_616514 != nil:
    section.add "X-Amz-SignedHeaders", valid_616514
  var valid_616515 = header.getOrDefault("X-Amz-Target")
  valid_616515 = validateParameter(valid_616515, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateProductWithPortfolio"))
  if valid_616515 != nil:
    section.add "X-Amz-Target", valid_616515
  var valid_616516 = header.getOrDefault("X-Amz-Credential")
  valid_616516 = validateParameter(valid_616516, JString, required = false,
                                 default = nil)
  if valid_616516 != nil:
    section.add "X-Amz-Credential", valid_616516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616518: Call_AssociateProductWithPortfolio_616506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified product with the specified portfolio.
  ## 
  let valid = call_616518.validator(path, query, header, formData, body)
  let scheme = call_616518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616518.url(scheme.get, call_616518.host, call_616518.base,
                         call_616518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616518, url, valid)

proc call*(call_616519: Call_AssociateProductWithPortfolio_616506; body: JsonNode): Recallable =
  ## associateProductWithPortfolio
  ## Associates the specified product with the specified portfolio.
  ##   body: JObject (required)
  var body_616520 = newJObject()
  if body != nil:
    body_616520 = body
  result = call_616519.call(nil, nil, nil, nil, body_616520)

var associateProductWithPortfolio* = Call_AssociateProductWithPortfolio_616506(
    name: "associateProductWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio",
    validator: validate_AssociateProductWithPortfolio_616507, base: "/",
    url: url_AssociateProductWithPortfolio_616508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceActionWithProvisioningArtifact_616521 = ref object of OpenApiRestCall_615866
proc url_AssociateServiceActionWithProvisioningArtifact_616523(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceActionWithProvisioningArtifact_616522(
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616524 = header.getOrDefault("X-Amz-Date")
  valid_616524 = validateParameter(valid_616524, JString, required = false,
                                 default = nil)
  if valid_616524 != nil:
    section.add "X-Amz-Date", valid_616524
  var valid_616525 = header.getOrDefault("X-Amz-Security-Token")
  valid_616525 = validateParameter(valid_616525, JString, required = false,
                                 default = nil)
  if valid_616525 != nil:
    section.add "X-Amz-Security-Token", valid_616525
  var valid_616526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616526 = validateParameter(valid_616526, JString, required = false,
                                 default = nil)
  if valid_616526 != nil:
    section.add "X-Amz-Content-Sha256", valid_616526
  var valid_616527 = header.getOrDefault("X-Amz-Algorithm")
  valid_616527 = validateParameter(valid_616527, JString, required = false,
                                 default = nil)
  if valid_616527 != nil:
    section.add "X-Amz-Algorithm", valid_616527
  var valid_616528 = header.getOrDefault("X-Amz-Signature")
  valid_616528 = validateParameter(valid_616528, JString, required = false,
                                 default = nil)
  if valid_616528 != nil:
    section.add "X-Amz-Signature", valid_616528
  var valid_616529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616529 = validateParameter(valid_616529, JString, required = false,
                                 default = nil)
  if valid_616529 != nil:
    section.add "X-Amz-SignedHeaders", valid_616529
  var valid_616530 = header.getOrDefault("X-Amz-Target")
  valid_616530 = validateParameter(valid_616530, JString, required = true, default = newJString("AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"))
  if valid_616530 != nil:
    section.add "X-Amz-Target", valid_616530
  var valid_616531 = header.getOrDefault("X-Amz-Credential")
  valid_616531 = validateParameter(valid_616531, JString, required = false,
                                 default = nil)
  if valid_616531 != nil:
    section.add "X-Amz-Credential", valid_616531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616533: Call_AssociateServiceActionWithProvisioningArtifact_616521;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a self-service action with a provisioning artifact.
  ## 
  let valid = call_616533.validator(path, query, header, formData, body)
  let scheme = call_616533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616533.url(scheme.get, call_616533.host, call_616533.base,
                         call_616533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616533, url, valid)

proc call*(call_616534: Call_AssociateServiceActionWithProvisioningArtifact_616521;
          body: JsonNode): Recallable =
  ## associateServiceActionWithProvisioningArtifact
  ## Associates a self-service action with a provisioning artifact.
  ##   body: JObject (required)
  var body_616535 = newJObject()
  if body != nil:
    body_616535 = body
  result = call_616534.call(nil, nil, nil, nil, body_616535)

var associateServiceActionWithProvisioningArtifact* = Call_AssociateServiceActionWithProvisioningArtifact_616521(
    name: "associateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact",
    validator: validate_AssociateServiceActionWithProvisioningArtifact_616522,
    base: "/", url: url_AssociateServiceActionWithProvisioningArtifact_616523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTagOptionWithResource_616536 = ref object of OpenApiRestCall_615866
proc url_AssociateTagOptionWithResource_616538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateTagOptionWithResource_616537(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616539 = header.getOrDefault("X-Amz-Date")
  valid_616539 = validateParameter(valid_616539, JString, required = false,
                                 default = nil)
  if valid_616539 != nil:
    section.add "X-Amz-Date", valid_616539
  var valid_616540 = header.getOrDefault("X-Amz-Security-Token")
  valid_616540 = validateParameter(valid_616540, JString, required = false,
                                 default = nil)
  if valid_616540 != nil:
    section.add "X-Amz-Security-Token", valid_616540
  var valid_616541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616541 = validateParameter(valid_616541, JString, required = false,
                                 default = nil)
  if valid_616541 != nil:
    section.add "X-Amz-Content-Sha256", valid_616541
  var valid_616542 = header.getOrDefault("X-Amz-Algorithm")
  valid_616542 = validateParameter(valid_616542, JString, required = false,
                                 default = nil)
  if valid_616542 != nil:
    section.add "X-Amz-Algorithm", valid_616542
  var valid_616543 = header.getOrDefault("X-Amz-Signature")
  valid_616543 = validateParameter(valid_616543, JString, required = false,
                                 default = nil)
  if valid_616543 != nil:
    section.add "X-Amz-Signature", valid_616543
  var valid_616544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616544 = validateParameter(valid_616544, JString, required = false,
                                 default = nil)
  if valid_616544 != nil:
    section.add "X-Amz-SignedHeaders", valid_616544
  var valid_616545 = header.getOrDefault("X-Amz-Target")
  valid_616545 = validateParameter(valid_616545, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateTagOptionWithResource"))
  if valid_616545 != nil:
    section.add "X-Amz-Target", valid_616545
  var valid_616546 = header.getOrDefault("X-Amz-Credential")
  valid_616546 = validateParameter(valid_616546, JString, required = false,
                                 default = nil)
  if valid_616546 != nil:
    section.add "X-Amz-Credential", valid_616546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616548: Call_AssociateTagOptionWithResource_616536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associate the specified TagOption with the specified portfolio or product.
  ## 
  let valid = call_616548.validator(path, query, header, formData, body)
  let scheme = call_616548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616548.url(scheme.get, call_616548.host, call_616548.base,
                         call_616548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616548, url, valid)

proc call*(call_616549: Call_AssociateTagOptionWithResource_616536; body: JsonNode): Recallable =
  ## associateTagOptionWithResource
  ## Associate the specified TagOption with the specified portfolio or product.
  ##   body: JObject (required)
  var body_616550 = newJObject()
  if body != nil:
    body_616550 = body
  result = call_616549.call(nil, nil, nil, nil, body_616550)

var associateTagOptionWithResource* = Call_AssociateTagOptionWithResource_616536(
    name: "associateTagOptionWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource",
    validator: validate_AssociateTagOptionWithResource_616537, base: "/",
    url: url_AssociateTagOptionWithResource_616538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateServiceActionWithProvisioningArtifact_616551 = ref object of OpenApiRestCall_615866
proc url_BatchAssociateServiceActionWithProvisioningArtifact_616553(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchAssociateServiceActionWithProvisioningArtifact_616552(
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616554 = header.getOrDefault("X-Amz-Date")
  valid_616554 = validateParameter(valid_616554, JString, required = false,
                                 default = nil)
  if valid_616554 != nil:
    section.add "X-Amz-Date", valid_616554
  var valid_616555 = header.getOrDefault("X-Amz-Security-Token")
  valid_616555 = validateParameter(valid_616555, JString, required = false,
                                 default = nil)
  if valid_616555 != nil:
    section.add "X-Amz-Security-Token", valid_616555
  var valid_616556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616556 = validateParameter(valid_616556, JString, required = false,
                                 default = nil)
  if valid_616556 != nil:
    section.add "X-Amz-Content-Sha256", valid_616556
  var valid_616557 = header.getOrDefault("X-Amz-Algorithm")
  valid_616557 = validateParameter(valid_616557, JString, required = false,
                                 default = nil)
  if valid_616557 != nil:
    section.add "X-Amz-Algorithm", valid_616557
  var valid_616558 = header.getOrDefault("X-Amz-Signature")
  valid_616558 = validateParameter(valid_616558, JString, required = false,
                                 default = nil)
  if valid_616558 != nil:
    section.add "X-Amz-Signature", valid_616558
  var valid_616559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616559 = validateParameter(valid_616559, JString, required = false,
                                 default = nil)
  if valid_616559 != nil:
    section.add "X-Amz-SignedHeaders", valid_616559
  var valid_616560 = header.getOrDefault("X-Amz-Target")
  valid_616560 = validateParameter(valid_616560, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"))
  if valid_616560 != nil:
    section.add "X-Amz-Target", valid_616560
  var valid_616561 = header.getOrDefault("X-Amz-Credential")
  valid_616561 = validateParameter(valid_616561, JString, required = false,
                                 default = nil)
  if valid_616561 != nil:
    section.add "X-Amz-Credential", valid_616561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616563: Call_BatchAssociateServiceActionWithProvisioningArtifact_616551;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates multiple self-service actions with provisioning artifacts.
  ## 
  let valid = call_616563.validator(path, query, header, formData, body)
  let scheme = call_616563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616563.url(scheme.get, call_616563.host, call_616563.base,
                         call_616563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616563, url, valid)

proc call*(call_616564: Call_BatchAssociateServiceActionWithProvisioningArtifact_616551;
          body: JsonNode): Recallable =
  ## batchAssociateServiceActionWithProvisioningArtifact
  ## Associates multiple self-service actions with provisioning artifacts.
  ##   body: JObject (required)
  var body_616565 = newJObject()
  if body != nil:
    body_616565 = body
  result = call_616564.call(nil, nil, nil, nil, body_616565)

var batchAssociateServiceActionWithProvisioningArtifact* = Call_BatchAssociateServiceActionWithProvisioningArtifact_616551(
    name: "batchAssociateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact",
    validator: validate_BatchAssociateServiceActionWithProvisioningArtifact_616552,
    base: "/", url: url_BatchAssociateServiceActionWithProvisioningArtifact_616553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateServiceActionFromProvisioningArtifact_616566 = ref object of OpenApiRestCall_615866
proc url_BatchDisassociateServiceActionFromProvisioningArtifact_616568(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisassociateServiceActionFromProvisioningArtifact_616567(
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616569 = header.getOrDefault("X-Amz-Date")
  valid_616569 = validateParameter(valid_616569, JString, required = false,
                                 default = nil)
  if valid_616569 != nil:
    section.add "X-Amz-Date", valid_616569
  var valid_616570 = header.getOrDefault("X-Amz-Security-Token")
  valid_616570 = validateParameter(valid_616570, JString, required = false,
                                 default = nil)
  if valid_616570 != nil:
    section.add "X-Amz-Security-Token", valid_616570
  var valid_616571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616571 = validateParameter(valid_616571, JString, required = false,
                                 default = nil)
  if valid_616571 != nil:
    section.add "X-Amz-Content-Sha256", valid_616571
  var valid_616572 = header.getOrDefault("X-Amz-Algorithm")
  valid_616572 = validateParameter(valid_616572, JString, required = false,
                                 default = nil)
  if valid_616572 != nil:
    section.add "X-Amz-Algorithm", valid_616572
  var valid_616573 = header.getOrDefault("X-Amz-Signature")
  valid_616573 = validateParameter(valid_616573, JString, required = false,
                                 default = nil)
  if valid_616573 != nil:
    section.add "X-Amz-Signature", valid_616573
  var valid_616574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616574 = validateParameter(valid_616574, JString, required = false,
                                 default = nil)
  if valid_616574 != nil:
    section.add "X-Amz-SignedHeaders", valid_616574
  var valid_616575 = header.getOrDefault("X-Amz-Target")
  valid_616575 = validateParameter(valid_616575, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"))
  if valid_616575 != nil:
    section.add "X-Amz-Target", valid_616575
  var valid_616576 = header.getOrDefault("X-Amz-Credential")
  valid_616576 = validateParameter(valid_616576, JString, required = false,
                                 default = nil)
  if valid_616576 != nil:
    section.add "X-Amz-Credential", valid_616576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616578: Call_BatchDisassociateServiceActionFromProvisioningArtifact_616566;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ## 
  let valid = call_616578.validator(path, query, header, formData, body)
  let scheme = call_616578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616578.url(scheme.get, call_616578.host, call_616578.base,
                         call_616578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616578, url, valid)

proc call*(call_616579: Call_BatchDisassociateServiceActionFromProvisioningArtifact_616566;
          body: JsonNode): Recallable =
  ## batchDisassociateServiceActionFromProvisioningArtifact
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_616580 = newJObject()
  if body != nil:
    body_616580 = body
  result = call_616579.call(nil, nil, nil, nil, body_616580)

var batchDisassociateServiceActionFromProvisioningArtifact* = Call_BatchDisassociateServiceActionFromProvisioningArtifact_616566(
    name: "batchDisassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact",
    validator: validate_BatchDisassociateServiceActionFromProvisioningArtifact_616567,
    base: "/", url: url_BatchDisassociateServiceActionFromProvisioningArtifact_616568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyProduct_616581 = ref object of OpenApiRestCall_615866
proc url_CopyProduct_616583(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CopyProduct_616582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616584 = header.getOrDefault("X-Amz-Date")
  valid_616584 = validateParameter(valid_616584, JString, required = false,
                                 default = nil)
  if valid_616584 != nil:
    section.add "X-Amz-Date", valid_616584
  var valid_616585 = header.getOrDefault("X-Amz-Security-Token")
  valid_616585 = validateParameter(valid_616585, JString, required = false,
                                 default = nil)
  if valid_616585 != nil:
    section.add "X-Amz-Security-Token", valid_616585
  var valid_616586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616586 = validateParameter(valid_616586, JString, required = false,
                                 default = nil)
  if valid_616586 != nil:
    section.add "X-Amz-Content-Sha256", valid_616586
  var valid_616587 = header.getOrDefault("X-Amz-Algorithm")
  valid_616587 = validateParameter(valid_616587, JString, required = false,
                                 default = nil)
  if valid_616587 != nil:
    section.add "X-Amz-Algorithm", valid_616587
  var valid_616588 = header.getOrDefault("X-Amz-Signature")
  valid_616588 = validateParameter(valid_616588, JString, required = false,
                                 default = nil)
  if valid_616588 != nil:
    section.add "X-Amz-Signature", valid_616588
  var valid_616589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616589 = validateParameter(valid_616589, JString, required = false,
                                 default = nil)
  if valid_616589 != nil:
    section.add "X-Amz-SignedHeaders", valid_616589
  var valid_616590 = header.getOrDefault("X-Amz-Target")
  valid_616590 = validateParameter(valid_616590, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CopyProduct"))
  if valid_616590 != nil:
    section.add "X-Amz-Target", valid_616590
  var valid_616591 = header.getOrDefault("X-Amz-Credential")
  valid_616591 = validateParameter(valid_616591, JString, required = false,
                                 default = nil)
  if valid_616591 != nil:
    section.add "X-Amz-Credential", valid_616591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616593: Call_CopyProduct_616581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ## 
  let valid = call_616593.validator(path, query, header, formData, body)
  let scheme = call_616593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616593.url(scheme.get, call_616593.host, call_616593.base,
                         call_616593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616593, url, valid)

proc call*(call_616594: Call_CopyProduct_616581; body: JsonNode): Recallable =
  ## copyProduct
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ##   body: JObject (required)
  var body_616595 = newJObject()
  if body != nil:
    body_616595 = body
  result = call_616594.call(nil, nil, nil, nil, body_616595)

var copyProduct* = Call_CopyProduct_616581(name: "copyProduct",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct",
                                        validator: validate_CopyProduct_616582,
                                        base: "/", url: url_CopyProduct_616583,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConstraint_616596 = ref object of OpenApiRestCall_615866
proc url_CreateConstraint_616598(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConstraint_616597(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616599 = header.getOrDefault("X-Amz-Date")
  valid_616599 = validateParameter(valid_616599, JString, required = false,
                                 default = nil)
  if valid_616599 != nil:
    section.add "X-Amz-Date", valid_616599
  var valid_616600 = header.getOrDefault("X-Amz-Security-Token")
  valid_616600 = validateParameter(valid_616600, JString, required = false,
                                 default = nil)
  if valid_616600 != nil:
    section.add "X-Amz-Security-Token", valid_616600
  var valid_616601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616601 = validateParameter(valid_616601, JString, required = false,
                                 default = nil)
  if valid_616601 != nil:
    section.add "X-Amz-Content-Sha256", valid_616601
  var valid_616602 = header.getOrDefault("X-Amz-Algorithm")
  valid_616602 = validateParameter(valid_616602, JString, required = false,
                                 default = nil)
  if valid_616602 != nil:
    section.add "X-Amz-Algorithm", valid_616602
  var valid_616603 = header.getOrDefault("X-Amz-Signature")
  valid_616603 = validateParameter(valid_616603, JString, required = false,
                                 default = nil)
  if valid_616603 != nil:
    section.add "X-Amz-Signature", valid_616603
  var valid_616604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616604 = validateParameter(valid_616604, JString, required = false,
                                 default = nil)
  if valid_616604 != nil:
    section.add "X-Amz-SignedHeaders", valid_616604
  var valid_616605 = header.getOrDefault("X-Amz-Target")
  valid_616605 = validateParameter(valid_616605, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateConstraint"))
  if valid_616605 != nil:
    section.add "X-Amz-Target", valid_616605
  var valid_616606 = header.getOrDefault("X-Amz-Credential")
  valid_616606 = validateParameter(valid_616606, JString, required = false,
                                 default = nil)
  if valid_616606 != nil:
    section.add "X-Amz-Credential", valid_616606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616608: Call_CreateConstraint_616596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a constraint.
  ## 
  let valid = call_616608.validator(path, query, header, formData, body)
  let scheme = call_616608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616608.url(scheme.get, call_616608.host, call_616608.base,
                         call_616608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616608, url, valid)

proc call*(call_616609: Call_CreateConstraint_616596; body: JsonNode): Recallable =
  ## createConstraint
  ## Creates a constraint.
  ##   body: JObject (required)
  var body_616610 = newJObject()
  if body != nil:
    body_616610 = body
  result = call_616609.call(nil, nil, nil, nil, body_616610)

var createConstraint* = Call_CreateConstraint_616596(name: "createConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint",
    validator: validate_CreateConstraint_616597, base: "/",
    url: url_CreateConstraint_616598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolio_616611 = ref object of OpenApiRestCall_615866
proc url_CreatePortfolio_616613(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePortfolio_616612(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616614 = header.getOrDefault("X-Amz-Date")
  valid_616614 = validateParameter(valid_616614, JString, required = false,
                                 default = nil)
  if valid_616614 != nil:
    section.add "X-Amz-Date", valid_616614
  var valid_616615 = header.getOrDefault("X-Amz-Security-Token")
  valid_616615 = validateParameter(valid_616615, JString, required = false,
                                 default = nil)
  if valid_616615 != nil:
    section.add "X-Amz-Security-Token", valid_616615
  var valid_616616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616616 = validateParameter(valid_616616, JString, required = false,
                                 default = nil)
  if valid_616616 != nil:
    section.add "X-Amz-Content-Sha256", valid_616616
  var valid_616617 = header.getOrDefault("X-Amz-Algorithm")
  valid_616617 = validateParameter(valid_616617, JString, required = false,
                                 default = nil)
  if valid_616617 != nil:
    section.add "X-Amz-Algorithm", valid_616617
  var valid_616618 = header.getOrDefault("X-Amz-Signature")
  valid_616618 = validateParameter(valid_616618, JString, required = false,
                                 default = nil)
  if valid_616618 != nil:
    section.add "X-Amz-Signature", valid_616618
  var valid_616619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616619 = validateParameter(valid_616619, JString, required = false,
                                 default = nil)
  if valid_616619 != nil:
    section.add "X-Amz-SignedHeaders", valid_616619
  var valid_616620 = header.getOrDefault("X-Amz-Target")
  valid_616620 = validateParameter(valid_616620, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolio"))
  if valid_616620 != nil:
    section.add "X-Amz-Target", valid_616620
  var valid_616621 = header.getOrDefault("X-Amz-Credential")
  valid_616621 = validateParameter(valid_616621, JString, required = false,
                                 default = nil)
  if valid_616621 != nil:
    section.add "X-Amz-Credential", valid_616621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616623: Call_CreatePortfolio_616611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a portfolio.
  ## 
  let valid = call_616623.validator(path, query, header, formData, body)
  let scheme = call_616623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616623.url(scheme.get, call_616623.host, call_616623.base,
                         call_616623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616623, url, valid)

proc call*(call_616624: Call_CreatePortfolio_616611; body: JsonNode): Recallable =
  ## createPortfolio
  ## Creates a portfolio.
  ##   body: JObject (required)
  var body_616625 = newJObject()
  if body != nil:
    body_616625 = body
  result = call_616624.call(nil, nil, nil, nil, body_616625)

var createPortfolio* = Call_CreatePortfolio_616611(name: "createPortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio",
    validator: validate_CreatePortfolio_616612, base: "/", url: url_CreatePortfolio_616613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolioShare_616626 = ref object of OpenApiRestCall_615866
proc url_CreatePortfolioShare_616628(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePortfolioShare_616627(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616629 = header.getOrDefault("X-Amz-Date")
  valid_616629 = validateParameter(valid_616629, JString, required = false,
                                 default = nil)
  if valid_616629 != nil:
    section.add "X-Amz-Date", valid_616629
  var valid_616630 = header.getOrDefault("X-Amz-Security-Token")
  valid_616630 = validateParameter(valid_616630, JString, required = false,
                                 default = nil)
  if valid_616630 != nil:
    section.add "X-Amz-Security-Token", valid_616630
  var valid_616631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616631 = validateParameter(valid_616631, JString, required = false,
                                 default = nil)
  if valid_616631 != nil:
    section.add "X-Amz-Content-Sha256", valid_616631
  var valid_616632 = header.getOrDefault("X-Amz-Algorithm")
  valid_616632 = validateParameter(valid_616632, JString, required = false,
                                 default = nil)
  if valid_616632 != nil:
    section.add "X-Amz-Algorithm", valid_616632
  var valid_616633 = header.getOrDefault("X-Amz-Signature")
  valid_616633 = validateParameter(valid_616633, JString, required = false,
                                 default = nil)
  if valid_616633 != nil:
    section.add "X-Amz-Signature", valid_616633
  var valid_616634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616634 = validateParameter(valid_616634, JString, required = false,
                                 default = nil)
  if valid_616634 != nil:
    section.add "X-Amz-SignedHeaders", valid_616634
  var valid_616635 = header.getOrDefault("X-Amz-Target")
  valid_616635 = validateParameter(valid_616635, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolioShare"))
  if valid_616635 != nil:
    section.add "X-Amz-Target", valid_616635
  var valid_616636 = header.getOrDefault("X-Amz-Credential")
  valid_616636 = validateParameter(valid_616636, JString, required = false,
                                 default = nil)
  if valid_616636 != nil:
    section.add "X-Amz-Credential", valid_616636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616638: Call_CreatePortfolioShare_616626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ## 
  let valid = call_616638.validator(path, query, header, formData, body)
  let scheme = call_616638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616638.url(scheme.get, call_616638.host, call_616638.base,
                         call_616638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616638, url, valid)

proc call*(call_616639: Call_CreatePortfolioShare_616626; body: JsonNode): Recallable =
  ## createPortfolioShare
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ##   body: JObject (required)
  var body_616640 = newJObject()
  if body != nil:
    body_616640 = body
  result = call_616639.call(nil, nil, nil, nil, body_616640)

var createPortfolioShare* = Call_CreatePortfolioShare_616626(
    name: "createPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare",
    validator: validate_CreatePortfolioShare_616627, base: "/",
    url: url_CreatePortfolioShare_616628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProduct_616641 = ref object of OpenApiRestCall_615866
proc url_CreateProduct_616643(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProduct_616642(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616644 = header.getOrDefault("X-Amz-Date")
  valid_616644 = validateParameter(valid_616644, JString, required = false,
                                 default = nil)
  if valid_616644 != nil:
    section.add "X-Amz-Date", valid_616644
  var valid_616645 = header.getOrDefault("X-Amz-Security-Token")
  valid_616645 = validateParameter(valid_616645, JString, required = false,
                                 default = nil)
  if valid_616645 != nil:
    section.add "X-Amz-Security-Token", valid_616645
  var valid_616646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616646 = validateParameter(valid_616646, JString, required = false,
                                 default = nil)
  if valid_616646 != nil:
    section.add "X-Amz-Content-Sha256", valid_616646
  var valid_616647 = header.getOrDefault("X-Amz-Algorithm")
  valid_616647 = validateParameter(valid_616647, JString, required = false,
                                 default = nil)
  if valid_616647 != nil:
    section.add "X-Amz-Algorithm", valid_616647
  var valid_616648 = header.getOrDefault("X-Amz-Signature")
  valid_616648 = validateParameter(valid_616648, JString, required = false,
                                 default = nil)
  if valid_616648 != nil:
    section.add "X-Amz-Signature", valid_616648
  var valid_616649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616649 = validateParameter(valid_616649, JString, required = false,
                                 default = nil)
  if valid_616649 != nil:
    section.add "X-Amz-SignedHeaders", valid_616649
  var valid_616650 = header.getOrDefault("X-Amz-Target")
  valid_616650 = validateParameter(valid_616650, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProduct"))
  if valid_616650 != nil:
    section.add "X-Amz-Target", valid_616650
  var valid_616651 = header.getOrDefault("X-Amz-Credential")
  valid_616651 = validateParameter(valid_616651, JString, required = false,
                                 default = nil)
  if valid_616651 != nil:
    section.add "X-Amz-Credential", valid_616651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616653: Call_CreateProduct_616641; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a product.
  ## 
  let valid = call_616653.validator(path, query, header, formData, body)
  let scheme = call_616653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616653.url(scheme.get, call_616653.host, call_616653.base,
                         call_616653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616653, url, valid)

proc call*(call_616654: Call_CreateProduct_616641; body: JsonNode): Recallable =
  ## createProduct
  ## Creates a product.
  ##   body: JObject (required)
  var body_616655 = newJObject()
  if body != nil:
    body_616655 = body
  result = call_616654.call(nil, nil, nil, nil, body_616655)

var createProduct* = Call_CreateProduct_616641(name: "createProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct",
    validator: validate_CreateProduct_616642, base: "/", url: url_CreateProduct_616643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisionedProductPlan_616656 = ref object of OpenApiRestCall_615866
proc url_CreateProvisionedProductPlan_616658(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProvisionedProductPlan_616657(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616659 = header.getOrDefault("X-Amz-Date")
  valid_616659 = validateParameter(valid_616659, JString, required = false,
                                 default = nil)
  if valid_616659 != nil:
    section.add "X-Amz-Date", valid_616659
  var valid_616660 = header.getOrDefault("X-Amz-Security-Token")
  valid_616660 = validateParameter(valid_616660, JString, required = false,
                                 default = nil)
  if valid_616660 != nil:
    section.add "X-Amz-Security-Token", valid_616660
  var valid_616661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616661 = validateParameter(valid_616661, JString, required = false,
                                 default = nil)
  if valid_616661 != nil:
    section.add "X-Amz-Content-Sha256", valid_616661
  var valid_616662 = header.getOrDefault("X-Amz-Algorithm")
  valid_616662 = validateParameter(valid_616662, JString, required = false,
                                 default = nil)
  if valid_616662 != nil:
    section.add "X-Amz-Algorithm", valid_616662
  var valid_616663 = header.getOrDefault("X-Amz-Signature")
  valid_616663 = validateParameter(valid_616663, JString, required = false,
                                 default = nil)
  if valid_616663 != nil:
    section.add "X-Amz-Signature", valid_616663
  var valid_616664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616664 = validateParameter(valid_616664, JString, required = false,
                                 default = nil)
  if valid_616664 != nil:
    section.add "X-Amz-SignedHeaders", valid_616664
  var valid_616665 = header.getOrDefault("X-Amz-Target")
  valid_616665 = validateParameter(valid_616665, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisionedProductPlan"))
  if valid_616665 != nil:
    section.add "X-Amz-Target", valid_616665
  var valid_616666 = header.getOrDefault("X-Amz-Credential")
  valid_616666 = validateParameter(valid_616666, JString, required = false,
                                 default = nil)
  if valid_616666 != nil:
    section.add "X-Amz-Credential", valid_616666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616668: Call_CreateProvisionedProductPlan_616656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ## 
  let valid = call_616668.validator(path, query, header, formData, body)
  let scheme = call_616668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616668.url(scheme.get, call_616668.host, call_616668.base,
                         call_616668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616668, url, valid)

proc call*(call_616669: Call_CreateProvisionedProductPlan_616656; body: JsonNode): Recallable =
  ## createProvisionedProductPlan
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ##   body: JObject (required)
  var body_616670 = newJObject()
  if body != nil:
    body_616670 = body
  result = call_616669.call(nil, nil, nil, nil, body_616670)

var createProvisionedProductPlan* = Call_CreateProvisionedProductPlan_616656(
    name: "createProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan",
    validator: validate_CreateProvisionedProductPlan_616657, base: "/",
    url: url_CreateProvisionedProductPlan_616658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisioningArtifact_616671 = ref object of OpenApiRestCall_615866
proc url_CreateProvisioningArtifact_616673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProvisioningArtifact_616672(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616674 = header.getOrDefault("X-Amz-Date")
  valid_616674 = validateParameter(valid_616674, JString, required = false,
                                 default = nil)
  if valid_616674 != nil:
    section.add "X-Amz-Date", valid_616674
  var valid_616675 = header.getOrDefault("X-Amz-Security-Token")
  valid_616675 = validateParameter(valid_616675, JString, required = false,
                                 default = nil)
  if valid_616675 != nil:
    section.add "X-Amz-Security-Token", valid_616675
  var valid_616676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616676 = validateParameter(valid_616676, JString, required = false,
                                 default = nil)
  if valid_616676 != nil:
    section.add "X-Amz-Content-Sha256", valid_616676
  var valid_616677 = header.getOrDefault("X-Amz-Algorithm")
  valid_616677 = validateParameter(valid_616677, JString, required = false,
                                 default = nil)
  if valid_616677 != nil:
    section.add "X-Amz-Algorithm", valid_616677
  var valid_616678 = header.getOrDefault("X-Amz-Signature")
  valid_616678 = validateParameter(valid_616678, JString, required = false,
                                 default = nil)
  if valid_616678 != nil:
    section.add "X-Amz-Signature", valid_616678
  var valid_616679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616679 = validateParameter(valid_616679, JString, required = false,
                                 default = nil)
  if valid_616679 != nil:
    section.add "X-Amz-SignedHeaders", valid_616679
  var valid_616680 = header.getOrDefault("X-Amz-Target")
  valid_616680 = validateParameter(valid_616680, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisioningArtifact"))
  if valid_616680 != nil:
    section.add "X-Amz-Target", valid_616680
  var valid_616681 = header.getOrDefault("X-Amz-Credential")
  valid_616681 = validateParameter(valid_616681, JString, required = false,
                                 default = nil)
  if valid_616681 != nil:
    section.add "X-Amz-Credential", valid_616681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616683: Call_CreateProvisioningArtifact_616671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_616683.validator(path, query, header, formData, body)
  let scheme = call_616683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616683.url(scheme.get, call_616683.host, call_616683.base,
                         call_616683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616683, url, valid)

proc call*(call_616684: Call_CreateProvisioningArtifact_616671; body: JsonNode): Recallable =
  ## createProvisioningArtifact
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_616685 = newJObject()
  if body != nil:
    body_616685 = body
  result = call_616684.call(nil, nil, nil, nil, body_616685)

var createProvisioningArtifact* = Call_CreateProvisioningArtifact_616671(
    name: "createProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact",
    validator: validate_CreateProvisioningArtifact_616672, base: "/",
    url: url_CreateProvisioningArtifact_616673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServiceAction_616686 = ref object of OpenApiRestCall_615866
proc url_CreateServiceAction_616688(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateServiceAction_616687(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616689 = header.getOrDefault("X-Amz-Date")
  valid_616689 = validateParameter(valid_616689, JString, required = false,
                                 default = nil)
  if valid_616689 != nil:
    section.add "X-Amz-Date", valid_616689
  var valid_616690 = header.getOrDefault("X-Amz-Security-Token")
  valid_616690 = validateParameter(valid_616690, JString, required = false,
                                 default = nil)
  if valid_616690 != nil:
    section.add "X-Amz-Security-Token", valid_616690
  var valid_616691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616691 = validateParameter(valid_616691, JString, required = false,
                                 default = nil)
  if valid_616691 != nil:
    section.add "X-Amz-Content-Sha256", valid_616691
  var valid_616692 = header.getOrDefault("X-Amz-Algorithm")
  valid_616692 = validateParameter(valid_616692, JString, required = false,
                                 default = nil)
  if valid_616692 != nil:
    section.add "X-Amz-Algorithm", valid_616692
  var valid_616693 = header.getOrDefault("X-Amz-Signature")
  valid_616693 = validateParameter(valid_616693, JString, required = false,
                                 default = nil)
  if valid_616693 != nil:
    section.add "X-Amz-Signature", valid_616693
  var valid_616694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616694 = validateParameter(valid_616694, JString, required = false,
                                 default = nil)
  if valid_616694 != nil:
    section.add "X-Amz-SignedHeaders", valid_616694
  var valid_616695 = header.getOrDefault("X-Amz-Target")
  valid_616695 = validateParameter(valid_616695, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateServiceAction"))
  if valid_616695 != nil:
    section.add "X-Amz-Target", valid_616695
  var valid_616696 = header.getOrDefault("X-Amz-Credential")
  valid_616696 = validateParameter(valid_616696, JString, required = false,
                                 default = nil)
  if valid_616696 != nil:
    section.add "X-Amz-Credential", valid_616696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616698: Call_CreateServiceAction_616686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a self-service action.
  ## 
  let valid = call_616698.validator(path, query, header, formData, body)
  let scheme = call_616698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616698.url(scheme.get, call_616698.host, call_616698.base,
                         call_616698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616698, url, valid)

proc call*(call_616699: Call_CreateServiceAction_616686; body: JsonNode): Recallable =
  ## createServiceAction
  ## Creates a self-service action.
  ##   body: JObject (required)
  var body_616700 = newJObject()
  if body != nil:
    body_616700 = body
  result = call_616699.call(nil, nil, nil, nil, body_616700)

var createServiceAction* = Call_CreateServiceAction_616686(
    name: "createServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction",
    validator: validate_CreateServiceAction_616687, base: "/",
    url: url_CreateServiceAction_616688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTagOption_616701 = ref object of OpenApiRestCall_615866
proc url_CreateTagOption_616703(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTagOption_616702(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616704 = header.getOrDefault("X-Amz-Date")
  valid_616704 = validateParameter(valid_616704, JString, required = false,
                                 default = nil)
  if valid_616704 != nil:
    section.add "X-Amz-Date", valid_616704
  var valid_616705 = header.getOrDefault("X-Amz-Security-Token")
  valid_616705 = validateParameter(valid_616705, JString, required = false,
                                 default = nil)
  if valid_616705 != nil:
    section.add "X-Amz-Security-Token", valid_616705
  var valid_616706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616706 = validateParameter(valid_616706, JString, required = false,
                                 default = nil)
  if valid_616706 != nil:
    section.add "X-Amz-Content-Sha256", valid_616706
  var valid_616707 = header.getOrDefault("X-Amz-Algorithm")
  valid_616707 = validateParameter(valid_616707, JString, required = false,
                                 default = nil)
  if valid_616707 != nil:
    section.add "X-Amz-Algorithm", valid_616707
  var valid_616708 = header.getOrDefault("X-Amz-Signature")
  valid_616708 = validateParameter(valid_616708, JString, required = false,
                                 default = nil)
  if valid_616708 != nil:
    section.add "X-Amz-Signature", valid_616708
  var valid_616709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616709 = validateParameter(valid_616709, JString, required = false,
                                 default = nil)
  if valid_616709 != nil:
    section.add "X-Amz-SignedHeaders", valid_616709
  var valid_616710 = header.getOrDefault("X-Amz-Target")
  valid_616710 = validateParameter(valid_616710, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateTagOption"))
  if valid_616710 != nil:
    section.add "X-Amz-Target", valid_616710
  var valid_616711 = header.getOrDefault("X-Amz-Credential")
  valid_616711 = validateParameter(valid_616711, JString, required = false,
                                 default = nil)
  if valid_616711 != nil:
    section.add "X-Amz-Credential", valid_616711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616713: Call_CreateTagOption_616701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a TagOption.
  ## 
  let valid = call_616713.validator(path, query, header, formData, body)
  let scheme = call_616713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616713.url(scheme.get, call_616713.host, call_616713.base,
                         call_616713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616713, url, valid)

proc call*(call_616714: Call_CreateTagOption_616701; body: JsonNode): Recallable =
  ## createTagOption
  ## Creates a TagOption.
  ##   body: JObject (required)
  var body_616715 = newJObject()
  if body != nil:
    body_616715 = body
  result = call_616714.call(nil, nil, nil, nil, body_616715)

var createTagOption* = Call_CreateTagOption_616701(name: "createTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption",
    validator: validate_CreateTagOption_616702, base: "/", url: url_CreateTagOption_616703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConstraint_616716 = ref object of OpenApiRestCall_615866
proc url_DeleteConstraint_616718(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConstraint_616717(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616719 = header.getOrDefault("X-Amz-Date")
  valid_616719 = validateParameter(valid_616719, JString, required = false,
                                 default = nil)
  if valid_616719 != nil:
    section.add "X-Amz-Date", valid_616719
  var valid_616720 = header.getOrDefault("X-Amz-Security-Token")
  valid_616720 = validateParameter(valid_616720, JString, required = false,
                                 default = nil)
  if valid_616720 != nil:
    section.add "X-Amz-Security-Token", valid_616720
  var valid_616721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616721 = validateParameter(valid_616721, JString, required = false,
                                 default = nil)
  if valid_616721 != nil:
    section.add "X-Amz-Content-Sha256", valid_616721
  var valid_616722 = header.getOrDefault("X-Amz-Algorithm")
  valid_616722 = validateParameter(valid_616722, JString, required = false,
                                 default = nil)
  if valid_616722 != nil:
    section.add "X-Amz-Algorithm", valid_616722
  var valid_616723 = header.getOrDefault("X-Amz-Signature")
  valid_616723 = validateParameter(valid_616723, JString, required = false,
                                 default = nil)
  if valid_616723 != nil:
    section.add "X-Amz-Signature", valid_616723
  var valid_616724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616724 = validateParameter(valid_616724, JString, required = false,
                                 default = nil)
  if valid_616724 != nil:
    section.add "X-Amz-SignedHeaders", valid_616724
  var valid_616725 = header.getOrDefault("X-Amz-Target")
  valid_616725 = validateParameter(valid_616725, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteConstraint"))
  if valid_616725 != nil:
    section.add "X-Amz-Target", valid_616725
  var valid_616726 = header.getOrDefault("X-Amz-Credential")
  valid_616726 = validateParameter(valid_616726, JString, required = false,
                                 default = nil)
  if valid_616726 != nil:
    section.add "X-Amz-Credential", valid_616726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616728: Call_DeleteConstraint_616716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified constraint.
  ## 
  let valid = call_616728.validator(path, query, header, formData, body)
  let scheme = call_616728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616728.url(scheme.get, call_616728.host, call_616728.base,
                         call_616728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616728, url, valid)

proc call*(call_616729: Call_DeleteConstraint_616716; body: JsonNode): Recallable =
  ## deleteConstraint
  ## Deletes the specified constraint.
  ##   body: JObject (required)
  var body_616730 = newJObject()
  if body != nil:
    body_616730 = body
  result = call_616729.call(nil, nil, nil, nil, body_616730)

var deleteConstraint* = Call_DeleteConstraint_616716(name: "deleteConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint",
    validator: validate_DeleteConstraint_616717, base: "/",
    url: url_DeleteConstraint_616718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolio_616731 = ref object of OpenApiRestCall_615866
proc url_DeletePortfolio_616733(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePortfolio_616732(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616734 = header.getOrDefault("X-Amz-Date")
  valid_616734 = validateParameter(valid_616734, JString, required = false,
                                 default = nil)
  if valid_616734 != nil:
    section.add "X-Amz-Date", valid_616734
  var valid_616735 = header.getOrDefault("X-Amz-Security-Token")
  valid_616735 = validateParameter(valid_616735, JString, required = false,
                                 default = nil)
  if valid_616735 != nil:
    section.add "X-Amz-Security-Token", valid_616735
  var valid_616736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616736 = validateParameter(valid_616736, JString, required = false,
                                 default = nil)
  if valid_616736 != nil:
    section.add "X-Amz-Content-Sha256", valid_616736
  var valid_616737 = header.getOrDefault("X-Amz-Algorithm")
  valid_616737 = validateParameter(valid_616737, JString, required = false,
                                 default = nil)
  if valid_616737 != nil:
    section.add "X-Amz-Algorithm", valid_616737
  var valid_616738 = header.getOrDefault("X-Amz-Signature")
  valid_616738 = validateParameter(valid_616738, JString, required = false,
                                 default = nil)
  if valid_616738 != nil:
    section.add "X-Amz-Signature", valid_616738
  var valid_616739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616739 = validateParameter(valid_616739, JString, required = false,
                                 default = nil)
  if valid_616739 != nil:
    section.add "X-Amz-SignedHeaders", valid_616739
  var valid_616740 = header.getOrDefault("X-Amz-Target")
  valid_616740 = validateParameter(valid_616740, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolio"))
  if valid_616740 != nil:
    section.add "X-Amz-Target", valid_616740
  var valid_616741 = header.getOrDefault("X-Amz-Credential")
  valid_616741 = validateParameter(valid_616741, JString, required = false,
                                 default = nil)
  if valid_616741 != nil:
    section.add "X-Amz-Credential", valid_616741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616743: Call_DeletePortfolio_616731; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ## 
  let valid = call_616743.validator(path, query, header, formData, body)
  let scheme = call_616743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616743.url(scheme.get, call_616743.host, call_616743.base,
                         call_616743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616743, url, valid)

proc call*(call_616744: Call_DeletePortfolio_616731; body: JsonNode): Recallable =
  ## deletePortfolio
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ##   body: JObject (required)
  var body_616745 = newJObject()
  if body != nil:
    body_616745 = body
  result = call_616744.call(nil, nil, nil, nil, body_616745)

var deletePortfolio* = Call_DeletePortfolio_616731(name: "deletePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio",
    validator: validate_DeletePortfolio_616732, base: "/", url: url_DeletePortfolio_616733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolioShare_616746 = ref object of OpenApiRestCall_615866
proc url_DeletePortfolioShare_616748(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePortfolioShare_616747(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616749 = header.getOrDefault("X-Amz-Date")
  valid_616749 = validateParameter(valid_616749, JString, required = false,
                                 default = nil)
  if valid_616749 != nil:
    section.add "X-Amz-Date", valid_616749
  var valid_616750 = header.getOrDefault("X-Amz-Security-Token")
  valid_616750 = validateParameter(valid_616750, JString, required = false,
                                 default = nil)
  if valid_616750 != nil:
    section.add "X-Amz-Security-Token", valid_616750
  var valid_616751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616751 = validateParameter(valid_616751, JString, required = false,
                                 default = nil)
  if valid_616751 != nil:
    section.add "X-Amz-Content-Sha256", valid_616751
  var valid_616752 = header.getOrDefault("X-Amz-Algorithm")
  valid_616752 = validateParameter(valid_616752, JString, required = false,
                                 default = nil)
  if valid_616752 != nil:
    section.add "X-Amz-Algorithm", valid_616752
  var valid_616753 = header.getOrDefault("X-Amz-Signature")
  valid_616753 = validateParameter(valid_616753, JString, required = false,
                                 default = nil)
  if valid_616753 != nil:
    section.add "X-Amz-Signature", valid_616753
  var valid_616754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616754 = validateParameter(valid_616754, JString, required = false,
                                 default = nil)
  if valid_616754 != nil:
    section.add "X-Amz-SignedHeaders", valid_616754
  var valid_616755 = header.getOrDefault("X-Amz-Target")
  valid_616755 = validateParameter(valid_616755, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolioShare"))
  if valid_616755 != nil:
    section.add "X-Amz-Target", valid_616755
  var valid_616756 = header.getOrDefault("X-Amz-Credential")
  valid_616756 = validateParameter(valid_616756, JString, required = false,
                                 default = nil)
  if valid_616756 != nil:
    section.add "X-Amz-Credential", valid_616756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616758: Call_DeletePortfolioShare_616746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ## 
  let valid = call_616758.validator(path, query, header, formData, body)
  let scheme = call_616758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616758.url(scheme.get, call_616758.host, call_616758.base,
                         call_616758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616758, url, valid)

proc call*(call_616759: Call_DeletePortfolioShare_616746; body: JsonNode): Recallable =
  ## deletePortfolioShare
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ##   body: JObject (required)
  var body_616760 = newJObject()
  if body != nil:
    body_616760 = body
  result = call_616759.call(nil, nil, nil, nil, body_616760)

var deletePortfolioShare* = Call_DeletePortfolioShare_616746(
    name: "deletePortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare",
    validator: validate_DeletePortfolioShare_616747, base: "/",
    url: url_DeletePortfolioShare_616748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProduct_616761 = ref object of OpenApiRestCall_615866
proc url_DeleteProduct_616763(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProduct_616762(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616764 = header.getOrDefault("X-Amz-Date")
  valid_616764 = validateParameter(valid_616764, JString, required = false,
                                 default = nil)
  if valid_616764 != nil:
    section.add "X-Amz-Date", valid_616764
  var valid_616765 = header.getOrDefault("X-Amz-Security-Token")
  valid_616765 = validateParameter(valid_616765, JString, required = false,
                                 default = nil)
  if valid_616765 != nil:
    section.add "X-Amz-Security-Token", valid_616765
  var valid_616766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616766 = validateParameter(valid_616766, JString, required = false,
                                 default = nil)
  if valid_616766 != nil:
    section.add "X-Amz-Content-Sha256", valid_616766
  var valid_616767 = header.getOrDefault("X-Amz-Algorithm")
  valid_616767 = validateParameter(valid_616767, JString, required = false,
                                 default = nil)
  if valid_616767 != nil:
    section.add "X-Amz-Algorithm", valid_616767
  var valid_616768 = header.getOrDefault("X-Amz-Signature")
  valid_616768 = validateParameter(valid_616768, JString, required = false,
                                 default = nil)
  if valid_616768 != nil:
    section.add "X-Amz-Signature", valid_616768
  var valid_616769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616769 = validateParameter(valid_616769, JString, required = false,
                                 default = nil)
  if valid_616769 != nil:
    section.add "X-Amz-SignedHeaders", valid_616769
  var valid_616770 = header.getOrDefault("X-Amz-Target")
  valid_616770 = validateParameter(valid_616770, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProduct"))
  if valid_616770 != nil:
    section.add "X-Amz-Target", valid_616770
  var valid_616771 = header.getOrDefault("X-Amz-Credential")
  valid_616771 = validateParameter(valid_616771, JString, required = false,
                                 default = nil)
  if valid_616771 != nil:
    section.add "X-Amz-Credential", valid_616771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616773: Call_DeleteProduct_616761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ## 
  let valid = call_616773.validator(path, query, header, formData, body)
  let scheme = call_616773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616773.url(scheme.get, call_616773.host, call_616773.base,
                         call_616773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616773, url, valid)

proc call*(call_616774: Call_DeleteProduct_616761; body: JsonNode): Recallable =
  ## deleteProduct
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ##   body: JObject (required)
  var body_616775 = newJObject()
  if body != nil:
    body_616775 = body
  result = call_616774.call(nil, nil, nil, nil, body_616775)

var deleteProduct* = Call_DeleteProduct_616761(name: "deleteProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct",
    validator: validate_DeleteProduct_616762, base: "/", url: url_DeleteProduct_616763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedProductPlan_616776 = ref object of OpenApiRestCall_615866
proc url_DeleteProvisionedProductPlan_616778(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProvisionedProductPlan_616777(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616779 = header.getOrDefault("X-Amz-Date")
  valid_616779 = validateParameter(valid_616779, JString, required = false,
                                 default = nil)
  if valid_616779 != nil:
    section.add "X-Amz-Date", valid_616779
  var valid_616780 = header.getOrDefault("X-Amz-Security-Token")
  valid_616780 = validateParameter(valid_616780, JString, required = false,
                                 default = nil)
  if valid_616780 != nil:
    section.add "X-Amz-Security-Token", valid_616780
  var valid_616781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616781 = validateParameter(valid_616781, JString, required = false,
                                 default = nil)
  if valid_616781 != nil:
    section.add "X-Amz-Content-Sha256", valid_616781
  var valid_616782 = header.getOrDefault("X-Amz-Algorithm")
  valid_616782 = validateParameter(valid_616782, JString, required = false,
                                 default = nil)
  if valid_616782 != nil:
    section.add "X-Amz-Algorithm", valid_616782
  var valid_616783 = header.getOrDefault("X-Amz-Signature")
  valid_616783 = validateParameter(valid_616783, JString, required = false,
                                 default = nil)
  if valid_616783 != nil:
    section.add "X-Amz-Signature", valid_616783
  var valid_616784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616784 = validateParameter(valid_616784, JString, required = false,
                                 default = nil)
  if valid_616784 != nil:
    section.add "X-Amz-SignedHeaders", valid_616784
  var valid_616785 = header.getOrDefault("X-Amz-Target")
  valid_616785 = validateParameter(valid_616785, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisionedProductPlan"))
  if valid_616785 != nil:
    section.add "X-Amz-Target", valid_616785
  var valid_616786 = header.getOrDefault("X-Amz-Credential")
  valid_616786 = validateParameter(valid_616786, JString, required = false,
                                 default = nil)
  if valid_616786 != nil:
    section.add "X-Amz-Credential", valid_616786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616788: Call_DeleteProvisionedProductPlan_616776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified plan.
  ## 
  let valid = call_616788.validator(path, query, header, formData, body)
  let scheme = call_616788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616788.url(scheme.get, call_616788.host, call_616788.base,
                         call_616788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616788, url, valid)

proc call*(call_616789: Call_DeleteProvisionedProductPlan_616776; body: JsonNode): Recallable =
  ## deleteProvisionedProductPlan
  ## Deletes the specified plan.
  ##   body: JObject (required)
  var body_616790 = newJObject()
  if body != nil:
    body_616790 = body
  result = call_616789.call(nil, nil, nil, nil, body_616790)

var deleteProvisionedProductPlan* = Call_DeleteProvisionedProductPlan_616776(
    name: "deleteProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan",
    validator: validate_DeleteProvisionedProductPlan_616777, base: "/",
    url: url_DeleteProvisionedProductPlan_616778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisioningArtifact_616791 = ref object of OpenApiRestCall_615866
proc url_DeleteProvisioningArtifact_616793(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProvisioningArtifact_616792(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616794 = header.getOrDefault("X-Amz-Date")
  valid_616794 = validateParameter(valid_616794, JString, required = false,
                                 default = nil)
  if valid_616794 != nil:
    section.add "X-Amz-Date", valid_616794
  var valid_616795 = header.getOrDefault("X-Amz-Security-Token")
  valid_616795 = validateParameter(valid_616795, JString, required = false,
                                 default = nil)
  if valid_616795 != nil:
    section.add "X-Amz-Security-Token", valid_616795
  var valid_616796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616796 = validateParameter(valid_616796, JString, required = false,
                                 default = nil)
  if valid_616796 != nil:
    section.add "X-Amz-Content-Sha256", valid_616796
  var valid_616797 = header.getOrDefault("X-Amz-Algorithm")
  valid_616797 = validateParameter(valid_616797, JString, required = false,
                                 default = nil)
  if valid_616797 != nil:
    section.add "X-Amz-Algorithm", valid_616797
  var valid_616798 = header.getOrDefault("X-Amz-Signature")
  valid_616798 = validateParameter(valid_616798, JString, required = false,
                                 default = nil)
  if valid_616798 != nil:
    section.add "X-Amz-Signature", valid_616798
  var valid_616799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616799 = validateParameter(valid_616799, JString, required = false,
                                 default = nil)
  if valid_616799 != nil:
    section.add "X-Amz-SignedHeaders", valid_616799
  var valid_616800 = header.getOrDefault("X-Amz-Target")
  valid_616800 = validateParameter(valid_616800, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisioningArtifact"))
  if valid_616800 != nil:
    section.add "X-Amz-Target", valid_616800
  var valid_616801 = header.getOrDefault("X-Amz-Credential")
  valid_616801 = validateParameter(valid_616801, JString, required = false,
                                 default = nil)
  if valid_616801 != nil:
    section.add "X-Amz-Credential", valid_616801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616803: Call_DeleteProvisioningArtifact_616791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ## 
  let valid = call_616803.validator(path, query, header, formData, body)
  let scheme = call_616803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616803.url(scheme.get, call_616803.host, call_616803.base,
                         call_616803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616803, url, valid)

proc call*(call_616804: Call_DeleteProvisioningArtifact_616791; body: JsonNode): Recallable =
  ## deleteProvisioningArtifact
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ##   body: JObject (required)
  var body_616805 = newJObject()
  if body != nil:
    body_616805 = body
  result = call_616804.call(nil, nil, nil, nil, body_616805)

var deleteProvisioningArtifact* = Call_DeleteProvisioningArtifact_616791(
    name: "deleteProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact",
    validator: validate_DeleteProvisioningArtifact_616792, base: "/",
    url: url_DeleteProvisioningArtifact_616793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceAction_616806 = ref object of OpenApiRestCall_615866
proc url_DeleteServiceAction_616808(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServiceAction_616807(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616809 = header.getOrDefault("X-Amz-Date")
  valid_616809 = validateParameter(valid_616809, JString, required = false,
                                 default = nil)
  if valid_616809 != nil:
    section.add "X-Amz-Date", valid_616809
  var valid_616810 = header.getOrDefault("X-Amz-Security-Token")
  valid_616810 = validateParameter(valid_616810, JString, required = false,
                                 default = nil)
  if valid_616810 != nil:
    section.add "X-Amz-Security-Token", valid_616810
  var valid_616811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616811 = validateParameter(valid_616811, JString, required = false,
                                 default = nil)
  if valid_616811 != nil:
    section.add "X-Amz-Content-Sha256", valid_616811
  var valid_616812 = header.getOrDefault("X-Amz-Algorithm")
  valid_616812 = validateParameter(valid_616812, JString, required = false,
                                 default = nil)
  if valid_616812 != nil:
    section.add "X-Amz-Algorithm", valid_616812
  var valid_616813 = header.getOrDefault("X-Amz-Signature")
  valid_616813 = validateParameter(valid_616813, JString, required = false,
                                 default = nil)
  if valid_616813 != nil:
    section.add "X-Amz-Signature", valid_616813
  var valid_616814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616814 = validateParameter(valid_616814, JString, required = false,
                                 default = nil)
  if valid_616814 != nil:
    section.add "X-Amz-SignedHeaders", valid_616814
  var valid_616815 = header.getOrDefault("X-Amz-Target")
  valid_616815 = validateParameter(valid_616815, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteServiceAction"))
  if valid_616815 != nil:
    section.add "X-Amz-Target", valid_616815
  var valid_616816 = header.getOrDefault("X-Amz-Credential")
  valid_616816 = validateParameter(valid_616816, JString, required = false,
                                 default = nil)
  if valid_616816 != nil:
    section.add "X-Amz-Credential", valid_616816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616818: Call_DeleteServiceAction_616806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a self-service action.
  ## 
  let valid = call_616818.validator(path, query, header, formData, body)
  let scheme = call_616818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616818.url(scheme.get, call_616818.host, call_616818.base,
                         call_616818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616818, url, valid)

proc call*(call_616819: Call_DeleteServiceAction_616806; body: JsonNode): Recallable =
  ## deleteServiceAction
  ## Deletes a self-service action.
  ##   body: JObject (required)
  var body_616820 = newJObject()
  if body != nil:
    body_616820 = body
  result = call_616819.call(nil, nil, nil, nil, body_616820)

var deleteServiceAction* = Call_DeleteServiceAction_616806(
    name: "deleteServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction",
    validator: validate_DeleteServiceAction_616807, base: "/",
    url: url_DeleteServiceAction_616808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagOption_616821 = ref object of OpenApiRestCall_615866
proc url_DeleteTagOption_616823(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTagOption_616822(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616824 = header.getOrDefault("X-Amz-Date")
  valid_616824 = validateParameter(valid_616824, JString, required = false,
                                 default = nil)
  if valid_616824 != nil:
    section.add "X-Amz-Date", valid_616824
  var valid_616825 = header.getOrDefault("X-Amz-Security-Token")
  valid_616825 = validateParameter(valid_616825, JString, required = false,
                                 default = nil)
  if valid_616825 != nil:
    section.add "X-Amz-Security-Token", valid_616825
  var valid_616826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616826 = validateParameter(valid_616826, JString, required = false,
                                 default = nil)
  if valid_616826 != nil:
    section.add "X-Amz-Content-Sha256", valid_616826
  var valid_616827 = header.getOrDefault("X-Amz-Algorithm")
  valid_616827 = validateParameter(valid_616827, JString, required = false,
                                 default = nil)
  if valid_616827 != nil:
    section.add "X-Amz-Algorithm", valid_616827
  var valid_616828 = header.getOrDefault("X-Amz-Signature")
  valid_616828 = validateParameter(valid_616828, JString, required = false,
                                 default = nil)
  if valid_616828 != nil:
    section.add "X-Amz-Signature", valid_616828
  var valid_616829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616829 = validateParameter(valid_616829, JString, required = false,
                                 default = nil)
  if valid_616829 != nil:
    section.add "X-Amz-SignedHeaders", valid_616829
  var valid_616830 = header.getOrDefault("X-Amz-Target")
  valid_616830 = validateParameter(valid_616830, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteTagOption"))
  if valid_616830 != nil:
    section.add "X-Amz-Target", valid_616830
  var valid_616831 = header.getOrDefault("X-Amz-Credential")
  valid_616831 = validateParameter(valid_616831, JString, required = false,
                                 default = nil)
  if valid_616831 != nil:
    section.add "X-Amz-Credential", valid_616831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616833: Call_DeleteTagOption_616821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ## 
  let valid = call_616833.validator(path, query, header, formData, body)
  let scheme = call_616833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616833.url(scheme.get, call_616833.host, call_616833.base,
                         call_616833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616833, url, valid)

proc call*(call_616834: Call_DeleteTagOption_616821; body: JsonNode): Recallable =
  ## deleteTagOption
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ##   body: JObject (required)
  var body_616835 = newJObject()
  if body != nil:
    body_616835 = body
  result = call_616834.call(nil, nil, nil, nil, body_616835)

var deleteTagOption* = Call_DeleteTagOption_616821(name: "deleteTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption",
    validator: validate_DeleteTagOption_616822, base: "/", url: url_DeleteTagOption_616823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConstraint_616836 = ref object of OpenApiRestCall_615866
proc url_DescribeConstraint_616838(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConstraint_616837(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616839 = header.getOrDefault("X-Amz-Date")
  valid_616839 = validateParameter(valid_616839, JString, required = false,
                                 default = nil)
  if valid_616839 != nil:
    section.add "X-Amz-Date", valid_616839
  var valid_616840 = header.getOrDefault("X-Amz-Security-Token")
  valid_616840 = validateParameter(valid_616840, JString, required = false,
                                 default = nil)
  if valid_616840 != nil:
    section.add "X-Amz-Security-Token", valid_616840
  var valid_616841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616841 = validateParameter(valid_616841, JString, required = false,
                                 default = nil)
  if valid_616841 != nil:
    section.add "X-Amz-Content-Sha256", valid_616841
  var valid_616842 = header.getOrDefault("X-Amz-Algorithm")
  valid_616842 = validateParameter(valid_616842, JString, required = false,
                                 default = nil)
  if valid_616842 != nil:
    section.add "X-Amz-Algorithm", valid_616842
  var valid_616843 = header.getOrDefault("X-Amz-Signature")
  valid_616843 = validateParameter(valid_616843, JString, required = false,
                                 default = nil)
  if valid_616843 != nil:
    section.add "X-Amz-Signature", valid_616843
  var valid_616844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616844 = validateParameter(valid_616844, JString, required = false,
                                 default = nil)
  if valid_616844 != nil:
    section.add "X-Amz-SignedHeaders", valid_616844
  var valid_616845 = header.getOrDefault("X-Amz-Target")
  valid_616845 = validateParameter(valid_616845, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeConstraint"))
  if valid_616845 != nil:
    section.add "X-Amz-Target", valid_616845
  var valid_616846 = header.getOrDefault("X-Amz-Credential")
  valid_616846 = validateParameter(valid_616846, JString, required = false,
                                 default = nil)
  if valid_616846 != nil:
    section.add "X-Amz-Credential", valid_616846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616848: Call_DescribeConstraint_616836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified constraint.
  ## 
  let valid = call_616848.validator(path, query, header, formData, body)
  let scheme = call_616848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616848.url(scheme.get, call_616848.host, call_616848.base,
                         call_616848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616848, url, valid)

proc call*(call_616849: Call_DescribeConstraint_616836; body: JsonNode): Recallable =
  ## describeConstraint
  ## Gets information about the specified constraint.
  ##   body: JObject (required)
  var body_616850 = newJObject()
  if body != nil:
    body_616850 = body
  result = call_616849.call(nil, nil, nil, nil, body_616850)

var describeConstraint* = Call_DescribeConstraint_616836(
    name: "describeConstraint", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint",
    validator: validate_DescribeConstraint_616837, base: "/",
    url: url_DescribeConstraint_616838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyProductStatus_616851 = ref object of OpenApiRestCall_615866
proc url_DescribeCopyProductStatus_616853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCopyProductStatus_616852(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616854 = header.getOrDefault("X-Amz-Date")
  valid_616854 = validateParameter(valid_616854, JString, required = false,
                                 default = nil)
  if valid_616854 != nil:
    section.add "X-Amz-Date", valid_616854
  var valid_616855 = header.getOrDefault("X-Amz-Security-Token")
  valid_616855 = validateParameter(valid_616855, JString, required = false,
                                 default = nil)
  if valid_616855 != nil:
    section.add "X-Amz-Security-Token", valid_616855
  var valid_616856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616856 = validateParameter(valid_616856, JString, required = false,
                                 default = nil)
  if valid_616856 != nil:
    section.add "X-Amz-Content-Sha256", valid_616856
  var valid_616857 = header.getOrDefault("X-Amz-Algorithm")
  valid_616857 = validateParameter(valid_616857, JString, required = false,
                                 default = nil)
  if valid_616857 != nil:
    section.add "X-Amz-Algorithm", valid_616857
  var valid_616858 = header.getOrDefault("X-Amz-Signature")
  valid_616858 = validateParameter(valid_616858, JString, required = false,
                                 default = nil)
  if valid_616858 != nil:
    section.add "X-Amz-Signature", valid_616858
  var valid_616859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616859 = validateParameter(valid_616859, JString, required = false,
                                 default = nil)
  if valid_616859 != nil:
    section.add "X-Amz-SignedHeaders", valid_616859
  var valid_616860 = header.getOrDefault("X-Amz-Target")
  valid_616860 = validateParameter(valid_616860, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeCopyProductStatus"))
  if valid_616860 != nil:
    section.add "X-Amz-Target", valid_616860
  var valid_616861 = header.getOrDefault("X-Amz-Credential")
  valid_616861 = validateParameter(valid_616861, JString, required = false,
                                 default = nil)
  if valid_616861 != nil:
    section.add "X-Amz-Credential", valid_616861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616863: Call_DescribeCopyProductStatus_616851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified copy product operation.
  ## 
  let valid = call_616863.validator(path, query, header, formData, body)
  let scheme = call_616863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616863.url(scheme.get, call_616863.host, call_616863.base,
                         call_616863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616863, url, valid)

proc call*(call_616864: Call_DescribeCopyProductStatus_616851; body: JsonNode): Recallable =
  ## describeCopyProductStatus
  ## Gets the status of the specified copy product operation.
  ##   body: JObject (required)
  var body_616865 = newJObject()
  if body != nil:
    body_616865 = body
  result = call_616864.call(nil, nil, nil, nil, body_616865)

var describeCopyProductStatus* = Call_DescribeCopyProductStatus_616851(
    name: "describeCopyProductStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus",
    validator: validate_DescribeCopyProductStatus_616852, base: "/",
    url: url_DescribeCopyProductStatus_616853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolio_616866 = ref object of OpenApiRestCall_615866
proc url_DescribePortfolio_616868(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePortfolio_616867(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616869 = header.getOrDefault("X-Amz-Date")
  valid_616869 = validateParameter(valid_616869, JString, required = false,
                                 default = nil)
  if valid_616869 != nil:
    section.add "X-Amz-Date", valid_616869
  var valid_616870 = header.getOrDefault("X-Amz-Security-Token")
  valid_616870 = validateParameter(valid_616870, JString, required = false,
                                 default = nil)
  if valid_616870 != nil:
    section.add "X-Amz-Security-Token", valid_616870
  var valid_616871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616871 = validateParameter(valid_616871, JString, required = false,
                                 default = nil)
  if valid_616871 != nil:
    section.add "X-Amz-Content-Sha256", valid_616871
  var valid_616872 = header.getOrDefault("X-Amz-Algorithm")
  valid_616872 = validateParameter(valid_616872, JString, required = false,
                                 default = nil)
  if valid_616872 != nil:
    section.add "X-Amz-Algorithm", valid_616872
  var valid_616873 = header.getOrDefault("X-Amz-Signature")
  valid_616873 = validateParameter(valid_616873, JString, required = false,
                                 default = nil)
  if valid_616873 != nil:
    section.add "X-Amz-Signature", valid_616873
  var valid_616874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616874 = validateParameter(valid_616874, JString, required = false,
                                 default = nil)
  if valid_616874 != nil:
    section.add "X-Amz-SignedHeaders", valid_616874
  var valid_616875 = header.getOrDefault("X-Amz-Target")
  valid_616875 = validateParameter(valid_616875, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolio"))
  if valid_616875 != nil:
    section.add "X-Amz-Target", valid_616875
  var valid_616876 = header.getOrDefault("X-Amz-Credential")
  valid_616876 = validateParameter(valid_616876, JString, required = false,
                                 default = nil)
  if valid_616876 != nil:
    section.add "X-Amz-Credential", valid_616876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616878: Call_DescribePortfolio_616866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified portfolio.
  ## 
  let valid = call_616878.validator(path, query, header, formData, body)
  let scheme = call_616878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616878.url(scheme.get, call_616878.host, call_616878.base,
                         call_616878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616878, url, valid)

proc call*(call_616879: Call_DescribePortfolio_616866; body: JsonNode): Recallable =
  ## describePortfolio
  ## Gets information about the specified portfolio.
  ##   body: JObject (required)
  var body_616880 = newJObject()
  if body != nil:
    body_616880 = body
  result = call_616879.call(nil, nil, nil, nil, body_616880)

var describePortfolio* = Call_DescribePortfolio_616866(name: "describePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio",
    validator: validate_DescribePortfolio_616867, base: "/",
    url: url_DescribePortfolio_616868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolioShareStatus_616881 = ref object of OpenApiRestCall_615866
proc url_DescribePortfolioShareStatus_616883(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePortfolioShareStatus_616882(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616884 = header.getOrDefault("X-Amz-Date")
  valid_616884 = validateParameter(valid_616884, JString, required = false,
                                 default = nil)
  if valid_616884 != nil:
    section.add "X-Amz-Date", valid_616884
  var valid_616885 = header.getOrDefault("X-Amz-Security-Token")
  valid_616885 = validateParameter(valid_616885, JString, required = false,
                                 default = nil)
  if valid_616885 != nil:
    section.add "X-Amz-Security-Token", valid_616885
  var valid_616886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616886 = validateParameter(valid_616886, JString, required = false,
                                 default = nil)
  if valid_616886 != nil:
    section.add "X-Amz-Content-Sha256", valid_616886
  var valid_616887 = header.getOrDefault("X-Amz-Algorithm")
  valid_616887 = validateParameter(valid_616887, JString, required = false,
                                 default = nil)
  if valid_616887 != nil:
    section.add "X-Amz-Algorithm", valid_616887
  var valid_616888 = header.getOrDefault("X-Amz-Signature")
  valid_616888 = validateParameter(valid_616888, JString, required = false,
                                 default = nil)
  if valid_616888 != nil:
    section.add "X-Amz-Signature", valid_616888
  var valid_616889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616889 = validateParameter(valid_616889, JString, required = false,
                                 default = nil)
  if valid_616889 != nil:
    section.add "X-Amz-SignedHeaders", valid_616889
  var valid_616890 = header.getOrDefault("X-Amz-Target")
  valid_616890 = validateParameter(valid_616890, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolioShareStatus"))
  if valid_616890 != nil:
    section.add "X-Amz-Target", valid_616890
  var valid_616891 = header.getOrDefault("X-Amz-Credential")
  valid_616891 = validateParameter(valid_616891, JString, required = false,
                                 default = nil)
  if valid_616891 != nil:
    section.add "X-Amz-Credential", valid_616891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616893: Call_DescribePortfolioShareStatus_616881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ## 
  let valid = call_616893.validator(path, query, header, formData, body)
  let scheme = call_616893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616893.url(scheme.get, call_616893.host, call_616893.base,
                         call_616893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616893, url, valid)

proc call*(call_616894: Call_DescribePortfolioShareStatus_616881; body: JsonNode): Recallable =
  ## describePortfolioShareStatus
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_616895 = newJObject()
  if body != nil:
    body_616895 = body
  result = call_616894.call(nil, nil, nil, nil, body_616895)

var describePortfolioShareStatus* = Call_DescribePortfolioShareStatus_616881(
    name: "describePortfolioShareStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus",
    validator: validate_DescribePortfolioShareStatus_616882, base: "/",
    url: url_DescribePortfolioShareStatus_616883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProduct_616896 = ref object of OpenApiRestCall_615866
proc url_DescribeProduct_616898(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProduct_616897(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616899 = header.getOrDefault("X-Amz-Date")
  valid_616899 = validateParameter(valid_616899, JString, required = false,
                                 default = nil)
  if valid_616899 != nil:
    section.add "X-Amz-Date", valid_616899
  var valid_616900 = header.getOrDefault("X-Amz-Security-Token")
  valid_616900 = validateParameter(valid_616900, JString, required = false,
                                 default = nil)
  if valid_616900 != nil:
    section.add "X-Amz-Security-Token", valid_616900
  var valid_616901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616901 = validateParameter(valid_616901, JString, required = false,
                                 default = nil)
  if valid_616901 != nil:
    section.add "X-Amz-Content-Sha256", valid_616901
  var valid_616902 = header.getOrDefault("X-Amz-Algorithm")
  valid_616902 = validateParameter(valid_616902, JString, required = false,
                                 default = nil)
  if valid_616902 != nil:
    section.add "X-Amz-Algorithm", valid_616902
  var valid_616903 = header.getOrDefault("X-Amz-Signature")
  valid_616903 = validateParameter(valid_616903, JString, required = false,
                                 default = nil)
  if valid_616903 != nil:
    section.add "X-Amz-Signature", valid_616903
  var valid_616904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616904 = validateParameter(valid_616904, JString, required = false,
                                 default = nil)
  if valid_616904 != nil:
    section.add "X-Amz-SignedHeaders", valid_616904
  var valid_616905 = header.getOrDefault("X-Amz-Target")
  valid_616905 = validateParameter(valid_616905, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProduct"))
  if valid_616905 != nil:
    section.add "X-Amz-Target", valid_616905
  var valid_616906 = header.getOrDefault("X-Amz-Credential")
  valid_616906 = validateParameter(valid_616906, JString, required = false,
                                 default = nil)
  if valid_616906 != nil:
    section.add "X-Amz-Credential", valid_616906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616908: Call_DescribeProduct_616896; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_616908.validator(path, query, header, formData, body)
  let scheme = call_616908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616908.url(scheme.get, call_616908.host, call_616908.base,
                         call_616908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616908, url, valid)

proc call*(call_616909: Call_DescribeProduct_616896; body: JsonNode): Recallable =
  ## describeProduct
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_616910 = newJObject()
  if body != nil:
    body_616910 = body
  result = call_616909.call(nil, nil, nil, nil, body_616910)

var describeProduct* = Call_DescribeProduct_616896(name: "describeProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct",
    validator: validate_DescribeProduct_616897, base: "/", url: url_DescribeProduct_616898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductAsAdmin_616911 = ref object of OpenApiRestCall_615866
proc url_DescribeProductAsAdmin_616913(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProductAsAdmin_616912(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616914 = header.getOrDefault("X-Amz-Date")
  valid_616914 = validateParameter(valid_616914, JString, required = false,
                                 default = nil)
  if valid_616914 != nil:
    section.add "X-Amz-Date", valid_616914
  var valid_616915 = header.getOrDefault("X-Amz-Security-Token")
  valid_616915 = validateParameter(valid_616915, JString, required = false,
                                 default = nil)
  if valid_616915 != nil:
    section.add "X-Amz-Security-Token", valid_616915
  var valid_616916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616916 = validateParameter(valid_616916, JString, required = false,
                                 default = nil)
  if valid_616916 != nil:
    section.add "X-Amz-Content-Sha256", valid_616916
  var valid_616917 = header.getOrDefault("X-Amz-Algorithm")
  valid_616917 = validateParameter(valid_616917, JString, required = false,
                                 default = nil)
  if valid_616917 != nil:
    section.add "X-Amz-Algorithm", valid_616917
  var valid_616918 = header.getOrDefault("X-Amz-Signature")
  valid_616918 = validateParameter(valid_616918, JString, required = false,
                                 default = nil)
  if valid_616918 != nil:
    section.add "X-Amz-Signature", valid_616918
  var valid_616919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616919 = validateParameter(valid_616919, JString, required = false,
                                 default = nil)
  if valid_616919 != nil:
    section.add "X-Amz-SignedHeaders", valid_616919
  var valid_616920 = header.getOrDefault("X-Amz-Target")
  valid_616920 = validateParameter(valid_616920, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductAsAdmin"))
  if valid_616920 != nil:
    section.add "X-Amz-Target", valid_616920
  var valid_616921 = header.getOrDefault("X-Amz-Credential")
  valid_616921 = validateParameter(valid_616921, JString, required = false,
                                 default = nil)
  if valid_616921 != nil:
    section.add "X-Amz-Credential", valid_616921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616923: Call_DescribeProductAsAdmin_616911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product. This operation is run with administrator access.
  ## 
  let valid = call_616923.validator(path, query, header, formData, body)
  let scheme = call_616923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616923.url(scheme.get, call_616923.host, call_616923.base,
                         call_616923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616923, url, valid)

proc call*(call_616924: Call_DescribeProductAsAdmin_616911; body: JsonNode): Recallable =
  ## describeProductAsAdmin
  ## Gets information about the specified product. This operation is run with administrator access.
  ##   body: JObject (required)
  var body_616925 = newJObject()
  if body != nil:
    body_616925 = body
  result = call_616924.call(nil, nil, nil, nil, body_616925)

var describeProductAsAdmin* = Call_DescribeProductAsAdmin_616911(
    name: "describeProductAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin",
    validator: validate_DescribeProductAsAdmin_616912, base: "/",
    url: url_DescribeProductAsAdmin_616913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductView_616926 = ref object of OpenApiRestCall_615866
proc url_DescribeProductView_616928(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProductView_616927(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616929 = header.getOrDefault("X-Amz-Date")
  valid_616929 = validateParameter(valid_616929, JString, required = false,
                                 default = nil)
  if valid_616929 != nil:
    section.add "X-Amz-Date", valid_616929
  var valid_616930 = header.getOrDefault("X-Amz-Security-Token")
  valid_616930 = validateParameter(valid_616930, JString, required = false,
                                 default = nil)
  if valid_616930 != nil:
    section.add "X-Amz-Security-Token", valid_616930
  var valid_616931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616931 = validateParameter(valid_616931, JString, required = false,
                                 default = nil)
  if valid_616931 != nil:
    section.add "X-Amz-Content-Sha256", valid_616931
  var valid_616932 = header.getOrDefault("X-Amz-Algorithm")
  valid_616932 = validateParameter(valid_616932, JString, required = false,
                                 default = nil)
  if valid_616932 != nil:
    section.add "X-Amz-Algorithm", valid_616932
  var valid_616933 = header.getOrDefault("X-Amz-Signature")
  valid_616933 = validateParameter(valid_616933, JString, required = false,
                                 default = nil)
  if valid_616933 != nil:
    section.add "X-Amz-Signature", valid_616933
  var valid_616934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616934 = validateParameter(valid_616934, JString, required = false,
                                 default = nil)
  if valid_616934 != nil:
    section.add "X-Amz-SignedHeaders", valid_616934
  var valid_616935 = header.getOrDefault("X-Amz-Target")
  valid_616935 = validateParameter(valid_616935, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductView"))
  if valid_616935 != nil:
    section.add "X-Amz-Target", valid_616935
  var valid_616936 = header.getOrDefault("X-Amz-Credential")
  valid_616936 = validateParameter(valid_616936, JString, required = false,
                                 default = nil)
  if valid_616936 != nil:
    section.add "X-Amz-Credential", valid_616936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616938: Call_DescribeProductView_616926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_616938.validator(path, query, header, formData, body)
  let scheme = call_616938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616938.url(scheme.get, call_616938.host, call_616938.base,
                         call_616938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616938, url, valid)

proc call*(call_616939: Call_DescribeProductView_616926; body: JsonNode): Recallable =
  ## describeProductView
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_616940 = newJObject()
  if body != nil:
    body_616940 = body
  result = call_616939.call(nil, nil, nil, nil, body_616940)

var describeProductView* = Call_DescribeProductView_616926(
    name: "describeProductView", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView",
    validator: validate_DescribeProductView_616927, base: "/",
    url: url_DescribeProductView_616928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProduct_616941 = ref object of OpenApiRestCall_615866
proc url_DescribeProvisionedProduct_616943(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisionedProduct_616942(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616944 = header.getOrDefault("X-Amz-Date")
  valid_616944 = validateParameter(valid_616944, JString, required = false,
                                 default = nil)
  if valid_616944 != nil:
    section.add "X-Amz-Date", valid_616944
  var valid_616945 = header.getOrDefault("X-Amz-Security-Token")
  valid_616945 = validateParameter(valid_616945, JString, required = false,
                                 default = nil)
  if valid_616945 != nil:
    section.add "X-Amz-Security-Token", valid_616945
  var valid_616946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616946 = validateParameter(valid_616946, JString, required = false,
                                 default = nil)
  if valid_616946 != nil:
    section.add "X-Amz-Content-Sha256", valid_616946
  var valid_616947 = header.getOrDefault("X-Amz-Algorithm")
  valid_616947 = validateParameter(valid_616947, JString, required = false,
                                 default = nil)
  if valid_616947 != nil:
    section.add "X-Amz-Algorithm", valid_616947
  var valid_616948 = header.getOrDefault("X-Amz-Signature")
  valid_616948 = validateParameter(valid_616948, JString, required = false,
                                 default = nil)
  if valid_616948 != nil:
    section.add "X-Amz-Signature", valid_616948
  var valid_616949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616949 = validateParameter(valid_616949, JString, required = false,
                                 default = nil)
  if valid_616949 != nil:
    section.add "X-Amz-SignedHeaders", valid_616949
  var valid_616950 = header.getOrDefault("X-Amz-Target")
  valid_616950 = validateParameter(valid_616950, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProduct"))
  if valid_616950 != nil:
    section.add "X-Amz-Target", valid_616950
  var valid_616951 = header.getOrDefault("X-Amz-Credential")
  valid_616951 = validateParameter(valid_616951, JString, required = false,
                                 default = nil)
  if valid_616951 != nil:
    section.add "X-Amz-Credential", valid_616951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616953: Call_DescribeProvisionedProduct_616941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioned product.
  ## 
  let valid = call_616953.validator(path, query, header, formData, body)
  let scheme = call_616953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616953.url(scheme.get, call_616953.host, call_616953.base,
                         call_616953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616953, url, valid)

proc call*(call_616954: Call_DescribeProvisionedProduct_616941; body: JsonNode): Recallable =
  ## describeProvisionedProduct
  ## Gets information about the specified provisioned product.
  ##   body: JObject (required)
  var body_616955 = newJObject()
  if body != nil:
    body_616955 = body
  result = call_616954.call(nil, nil, nil, nil, body_616955)

var describeProvisionedProduct* = Call_DescribeProvisionedProduct_616941(
    name: "describeProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct",
    validator: validate_DescribeProvisionedProduct_616942, base: "/",
    url: url_DescribeProvisionedProduct_616943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProductPlan_616956 = ref object of OpenApiRestCall_615866
proc url_DescribeProvisionedProductPlan_616958(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisionedProductPlan_616957(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616959 = header.getOrDefault("X-Amz-Date")
  valid_616959 = validateParameter(valid_616959, JString, required = false,
                                 default = nil)
  if valid_616959 != nil:
    section.add "X-Amz-Date", valid_616959
  var valid_616960 = header.getOrDefault("X-Amz-Security-Token")
  valid_616960 = validateParameter(valid_616960, JString, required = false,
                                 default = nil)
  if valid_616960 != nil:
    section.add "X-Amz-Security-Token", valid_616960
  var valid_616961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616961 = validateParameter(valid_616961, JString, required = false,
                                 default = nil)
  if valid_616961 != nil:
    section.add "X-Amz-Content-Sha256", valid_616961
  var valid_616962 = header.getOrDefault("X-Amz-Algorithm")
  valid_616962 = validateParameter(valid_616962, JString, required = false,
                                 default = nil)
  if valid_616962 != nil:
    section.add "X-Amz-Algorithm", valid_616962
  var valid_616963 = header.getOrDefault("X-Amz-Signature")
  valid_616963 = validateParameter(valid_616963, JString, required = false,
                                 default = nil)
  if valid_616963 != nil:
    section.add "X-Amz-Signature", valid_616963
  var valid_616964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616964 = validateParameter(valid_616964, JString, required = false,
                                 default = nil)
  if valid_616964 != nil:
    section.add "X-Amz-SignedHeaders", valid_616964
  var valid_616965 = header.getOrDefault("X-Amz-Target")
  valid_616965 = validateParameter(valid_616965, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProductPlan"))
  if valid_616965 != nil:
    section.add "X-Amz-Target", valid_616965
  var valid_616966 = header.getOrDefault("X-Amz-Credential")
  valid_616966 = validateParameter(valid_616966, JString, required = false,
                                 default = nil)
  if valid_616966 != nil:
    section.add "X-Amz-Credential", valid_616966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616968: Call_DescribeProvisionedProductPlan_616956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the resource changes for the specified plan.
  ## 
  let valid = call_616968.validator(path, query, header, formData, body)
  let scheme = call_616968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616968.url(scheme.get, call_616968.host, call_616968.base,
                         call_616968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616968, url, valid)

proc call*(call_616969: Call_DescribeProvisionedProductPlan_616956; body: JsonNode): Recallable =
  ## describeProvisionedProductPlan
  ## Gets information about the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_616970 = newJObject()
  if body != nil:
    body_616970 = body
  result = call_616969.call(nil, nil, nil, nil, body_616970)

var describeProvisionedProductPlan* = Call_DescribeProvisionedProductPlan_616956(
    name: "describeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan",
    validator: validate_DescribeProvisionedProductPlan_616957, base: "/",
    url: url_DescribeProvisionedProductPlan_616958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningArtifact_616971 = ref object of OpenApiRestCall_615866
proc url_DescribeProvisioningArtifact_616973(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisioningArtifact_616972(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616974 = header.getOrDefault("X-Amz-Date")
  valid_616974 = validateParameter(valid_616974, JString, required = false,
                                 default = nil)
  if valid_616974 != nil:
    section.add "X-Amz-Date", valid_616974
  var valid_616975 = header.getOrDefault("X-Amz-Security-Token")
  valid_616975 = validateParameter(valid_616975, JString, required = false,
                                 default = nil)
  if valid_616975 != nil:
    section.add "X-Amz-Security-Token", valid_616975
  var valid_616976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616976 = validateParameter(valid_616976, JString, required = false,
                                 default = nil)
  if valid_616976 != nil:
    section.add "X-Amz-Content-Sha256", valid_616976
  var valid_616977 = header.getOrDefault("X-Amz-Algorithm")
  valid_616977 = validateParameter(valid_616977, JString, required = false,
                                 default = nil)
  if valid_616977 != nil:
    section.add "X-Amz-Algorithm", valid_616977
  var valid_616978 = header.getOrDefault("X-Amz-Signature")
  valid_616978 = validateParameter(valid_616978, JString, required = false,
                                 default = nil)
  if valid_616978 != nil:
    section.add "X-Amz-Signature", valid_616978
  var valid_616979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616979 = validateParameter(valid_616979, JString, required = false,
                                 default = nil)
  if valid_616979 != nil:
    section.add "X-Amz-SignedHeaders", valid_616979
  var valid_616980 = header.getOrDefault("X-Amz-Target")
  valid_616980 = validateParameter(valid_616980, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningArtifact"))
  if valid_616980 != nil:
    section.add "X-Amz-Target", valid_616980
  var valid_616981 = header.getOrDefault("X-Amz-Credential")
  valid_616981 = validateParameter(valid_616981, JString, required = false,
                                 default = nil)
  if valid_616981 != nil:
    section.add "X-Amz-Credential", valid_616981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616983: Call_DescribeProvisioningArtifact_616971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ## 
  let valid = call_616983.validator(path, query, header, formData, body)
  let scheme = call_616983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616983.url(scheme.get, call_616983.host, call_616983.base,
                         call_616983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616983, url, valid)

proc call*(call_616984: Call_DescribeProvisioningArtifact_616971; body: JsonNode): Recallable =
  ## describeProvisioningArtifact
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ##   body: JObject (required)
  var body_616985 = newJObject()
  if body != nil:
    body_616985 = body
  result = call_616984.call(nil, nil, nil, nil, body_616985)

var describeProvisioningArtifact* = Call_DescribeProvisioningArtifact_616971(
    name: "describeProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact",
    validator: validate_DescribeProvisioningArtifact_616972, base: "/",
    url: url_DescribeProvisioningArtifact_616973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningParameters_616986 = ref object of OpenApiRestCall_615866
proc url_DescribeProvisioningParameters_616988(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisioningParameters_616987(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_616989 = header.getOrDefault("X-Amz-Date")
  valid_616989 = validateParameter(valid_616989, JString, required = false,
                                 default = nil)
  if valid_616989 != nil:
    section.add "X-Amz-Date", valid_616989
  var valid_616990 = header.getOrDefault("X-Amz-Security-Token")
  valid_616990 = validateParameter(valid_616990, JString, required = false,
                                 default = nil)
  if valid_616990 != nil:
    section.add "X-Amz-Security-Token", valid_616990
  var valid_616991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616991 = validateParameter(valid_616991, JString, required = false,
                                 default = nil)
  if valid_616991 != nil:
    section.add "X-Amz-Content-Sha256", valid_616991
  var valid_616992 = header.getOrDefault("X-Amz-Algorithm")
  valid_616992 = validateParameter(valid_616992, JString, required = false,
                                 default = nil)
  if valid_616992 != nil:
    section.add "X-Amz-Algorithm", valid_616992
  var valid_616993 = header.getOrDefault("X-Amz-Signature")
  valid_616993 = validateParameter(valid_616993, JString, required = false,
                                 default = nil)
  if valid_616993 != nil:
    section.add "X-Amz-Signature", valid_616993
  var valid_616994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616994 = validateParameter(valid_616994, JString, required = false,
                                 default = nil)
  if valid_616994 != nil:
    section.add "X-Amz-SignedHeaders", valid_616994
  var valid_616995 = header.getOrDefault("X-Amz-Target")
  valid_616995 = validateParameter(valid_616995, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningParameters"))
  if valid_616995 != nil:
    section.add "X-Amz-Target", valid_616995
  var valid_616996 = header.getOrDefault("X-Amz-Credential")
  valid_616996 = validateParameter(valid_616996, JString, required = false,
                                 default = nil)
  if valid_616996 != nil:
    section.add "X-Amz-Credential", valid_616996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616998: Call_DescribeProvisioningParameters_616986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ## 
  let valid = call_616998.validator(path, query, header, formData, body)
  let scheme = call_616998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616998.url(scheme.get, call_616998.host, call_616998.base,
                         call_616998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616998, url, valid)

proc call*(call_616999: Call_DescribeProvisioningParameters_616986; body: JsonNode): Recallable =
  ## describeProvisioningParameters
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ##   body: JObject (required)
  var body_617000 = newJObject()
  if body != nil:
    body_617000 = body
  result = call_616999.call(nil, nil, nil, nil, body_617000)

var describeProvisioningParameters* = Call_DescribeProvisioningParameters_616986(
    name: "describeProvisioningParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters",
    validator: validate_DescribeProvisioningParameters_616987, base: "/",
    url: url_DescribeProvisioningParameters_616988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecord_617001 = ref object of OpenApiRestCall_615866
proc url_DescribeRecord_617003(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRecord_617002(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617004 = header.getOrDefault("X-Amz-Date")
  valid_617004 = validateParameter(valid_617004, JString, required = false,
                                 default = nil)
  if valid_617004 != nil:
    section.add "X-Amz-Date", valid_617004
  var valid_617005 = header.getOrDefault("X-Amz-Security-Token")
  valid_617005 = validateParameter(valid_617005, JString, required = false,
                                 default = nil)
  if valid_617005 != nil:
    section.add "X-Amz-Security-Token", valid_617005
  var valid_617006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617006 = validateParameter(valid_617006, JString, required = false,
                                 default = nil)
  if valid_617006 != nil:
    section.add "X-Amz-Content-Sha256", valid_617006
  var valid_617007 = header.getOrDefault("X-Amz-Algorithm")
  valid_617007 = validateParameter(valid_617007, JString, required = false,
                                 default = nil)
  if valid_617007 != nil:
    section.add "X-Amz-Algorithm", valid_617007
  var valid_617008 = header.getOrDefault("X-Amz-Signature")
  valid_617008 = validateParameter(valid_617008, JString, required = false,
                                 default = nil)
  if valid_617008 != nil:
    section.add "X-Amz-Signature", valid_617008
  var valid_617009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617009 = validateParameter(valid_617009, JString, required = false,
                                 default = nil)
  if valid_617009 != nil:
    section.add "X-Amz-SignedHeaders", valid_617009
  var valid_617010 = header.getOrDefault("X-Amz-Target")
  valid_617010 = validateParameter(valid_617010, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeRecord"))
  if valid_617010 != nil:
    section.add "X-Amz-Target", valid_617010
  var valid_617011 = header.getOrDefault("X-Amz-Credential")
  valid_617011 = validateParameter(valid_617011, JString, required = false,
                                 default = nil)
  if valid_617011 != nil:
    section.add "X-Amz-Credential", valid_617011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617013: Call_DescribeRecord_617001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ## 
  let valid = call_617013.validator(path, query, header, formData, body)
  let scheme = call_617013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617013.url(scheme.get, call_617013.host, call_617013.base,
                         call_617013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617013, url, valid)

proc call*(call_617014: Call_DescribeRecord_617001; body: JsonNode): Recallable =
  ## describeRecord
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ##   body: JObject (required)
  var body_617015 = newJObject()
  if body != nil:
    body_617015 = body
  result = call_617014.call(nil, nil, nil, nil, body_617015)

var describeRecord* = Call_DescribeRecord_617001(name: "describeRecord",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord",
    validator: validate_DescribeRecord_617002, base: "/", url: url_DescribeRecord_617003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceAction_617016 = ref object of OpenApiRestCall_615866
proc url_DescribeServiceAction_617018(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServiceAction_617017(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617019 = header.getOrDefault("X-Amz-Date")
  valid_617019 = validateParameter(valid_617019, JString, required = false,
                                 default = nil)
  if valid_617019 != nil:
    section.add "X-Amz-Date", valid_617019
  var valid_617020 = header.getOrDefault("X-Amz-Security-Token")
  valid_617020 = validateParameter(valid_617020, JString, required = false,
                                 default = nil)
  if valid_617020 != nil:
    section.add "X-Amz-Security-Token", valid_617020
  var valid_617021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617021 = validateParameter(valid_617021, JString, required = false,
                                 default = nil)
  if valid_617021 != nil:
    section.add "X-Amz-Content-Sha256", valid_617021
  var valid_617022 = header.getOrDefault("X-Amz-Algorithm")
  valid_617022 = validateParameter(valid_617022, JString, required = false,
                                 default = nil)
  if valid_617022 != nil:
    section.add "X-Amz-Algorithm", valid_617022
  var valid_617023 = header.getOrDefault("X-Amz-Signature")
  valid_617023 = validateParameter(valid_617023, JString, required = false,
                                 default = nil)
  if valid_617023 != nil:
    section.add "X-Amz-Signature", valid_617023
  var valid_617024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617024 = validateParameter(valid_617024, JString, required = false,
                                 default = nil)
  if valid_617024 != nil:
    section.add "X-Amz-SignedHeaders", valid_617024
  var valid_617025 = header.getOrDefault("X-Amz-Target")
  valid_617025 = validateParameter(valid_617025, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceAction"))
  if valid_617025 != nil:
    section.add "X-Amz-Target", valid_617025
  var valid_617026 = header.getOrDefault("X-Amz-Credential")
  valid_617026 = validateParameter(valid_617026, JString, required = false,
                                 default = nil)
  if valid_617026 != nil:
    section.add "X-Amz-Credential", valid_617026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617028: Call_DescribeServiceAction_617016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a self-service action.
  ## 
  let valid = call_617028.validator(path, query, header, formData, body)
  let scheme = call_617028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617028.url(scheme.get, call_617028.host, call_617028.base,
                         call_617028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617028, url, valid)

proc call*(call_617029: Call_DescribeServiceAction_617016; body: JsonNode): Recallable =
  ## describeServiceAction
  ## Describes a self-service action.
  ##   body: JObject (required)
  var body_617030 = newJObject()
  if body != nil:
    body_617030 = body
  result = call_617029.call(nil, nil, nil, nil, body_617030)

var describeServiceAction* = Call_DescribeServiceAction_617016(
    name: "describeServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction",
    validator: validate_DescribeServiceAction_617017, base: "/",
    url: url_DescribeServiceAction_617018, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceActionExecutionParameters_617031 = ref object of OpenApiRestCall_615866
proc url_DescribeServiceActionExecutionParameters_617033(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServiceActionExecutionParameters_617032(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Finds the default parameters for a specific self-service action on a specific provisioned product and returns a map of the results to the user.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617034 = header.getOrDefault("X-Amz-Date")
  valid_617034 = validateParameter(valid_617034, JString, required = false,
                                 default = nil)
  if valid_617034 != nil:
    section.add "X-Amz-Date", valid_617034
  var valid_617035 = header.getOrDefault("X-Amz-Security-Token")
  valid_617035 = validateParameter(valid_617035, JString, required = false,
                                 default = nil)
  if valid_617035 != nil:
    section.add "X-Amz-Security-Token", valid_617035
  var valid_617036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617036 = validateParameter(valid_617036, JString, required = false,
                                 default = nil)
  if valid_617036 != nil:
    section.add "X-Amz-Content-Sha256", valid_617036
  var valid_617037 = header.getOrDefault("X-Amz-Algorithm")
  valid_617037 = validateParameter(valid_617037, JString, required = false,
                                 default = nil)
  if valid_617037 != nil:
    section.add "X-Amz-Algorithm", valid_617037
  var valid_617038 = header.getOrDefault("X-Amz-Signature")
  valid_617038 = validateParameter(valid_617038, JString, required = false,
                                 default = nil)
  if valid_617038 != nil:
    section.add "X-Amz-Signature", valid_617038
  var valid_617039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617039 = validateParameter(valid_617039, JString, required = false,
                                 default = nil)
  if valid_617039 != nil:
    section.add "X-Amz-SignedHeaders", valid_617039
  var valid_617040 = header.getOrDefault("X-Amz-Target")
  valid_617040 = validateParameter(valid_617040, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"))
  if valid_617040 != nil:
    section.add "X-Amz-Target", valid_617040
  var valid_617041 = header.getOrDefault("X-Amz-Credential")
  valid_617041 = validateParameter(valid_617041, JString, required = false,
                                 default = nil)
  if valid_617041 != nil:
    section.add "X-Amz-Credential", valid_617041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617043: Call_DescribeServiceActionExecutionParameters_617031;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Finds the default parameters for a specific self-service action on a specific provisioned product and returns a map of the results to the user.
  ## 
  let valid = call_617043.validator(path, query, header, formData, body)
  let scheme = call_617043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617043.url(scheme.get, call_617043.host, call_617043.base,
                         call_617043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617043, url, valid)

proc call*(call_617044: Call_DescribeServiceActionExecutionParameters_617031;
          body: JsonNode): Recallable =
  ## describeServiceActionExecutionParameters
  ## Finds the default parameters for a specific self-service action on a specific provisioned product and returns a map of the results to the user.
  ##   body: JObject (required)
  var body_617045 = newJObject()
  if body != nil:
    body_617045 = body
  result = call_617044.call(nil, nil, nil, nil, body_617045)

var describeServiceActionExecutionParameters* = Call_DescribeServiceActionExecutionParameters_617031(
    name: "describeServiceActionExecutionParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters",
    validator: validate_DescribeServiceActionExecutionParameters_617032,
    base: "/", url: url_DescribeServiceActionExecutionParameters_617033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTagOption_617046 = ref object of OpenApiRestCall_615866
proc url_DescribeTagOption_617048(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTagOption_617047(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617049 = header.getOrDefault("X-Amz-Date")
  valid_617049 = validateParameter(valid_617049, JString, required = false,
                                 default = nil)
  if valid_617049 != nil:
    section.add "X-Amz-Date", valid_617049
  var valid_617050 = header.getOrDefault("X-Amz-Security-Token")
  valid_617050 = validateParameter(valid_617050, JString, required = false,
                                 default = nil)
  if valid_617050 != nil:
    section.add "X-Amz-Security-Token", valid_617050
  var valid_617051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617051 = validateParameter(valid_617051, JString, required = false,
                                 default = nil)
  if valid_617051 != nil:
    section.add "X-Amz-Content-Sha256", valid_617051
  var valid_617052 = header.getOrDefault("X-Amz-Algorithm")
  valid_617052 = validateParameter(valid_617052, JString, required = false,
                                 default = nil)
  if valid_617052 != nil:
    section.add "X-Amz-Algorithm", valid_617052
  var valid_617053 = header.getOrDefault("X-Amz-Signature")
  valid_617053 = validateParameter(valid_617053, JString, required = false,
                                 default = nil)
  if valid_617053 != nil:
    section.add "X-Amz-Signature", valid_617053
  var valid_617054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617054 = validateParameter(valid_617054, JString, required = false,
                                 default = nil)
  if valid_617054 != nil:
    section.add "X-Amz-SignedHeaders", valid_617054
  var valid_617055 = header.getOrDefault("X-Amz-Target")
  valid_617055 = validateParameter(valid_617055, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeTagOption"))
  if valid_617055 != nil:
    section.add "X-Amz-Target", valid_617055
  var valid_617056 = header.getOrDefault("X-Amz-Credential")
  valid_617056 = validateParameter(valid_617056, JString, required = false,
                                 default = nil)
  if valid_617056 != nil:
    section.add "X-Amz-Credential", valid_617056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617058: Call_DescribeTagOption_617046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified TagOption.
  ## 
  let valid = call_617058.validator(path, query, header, formData, body)
  let scheme = call_617058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617058.url(scheme.get, call_617058.host, call_617058.base,
                         call_617058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617058, url, valid)

proc call*(call_617059: Call_DescribeTagOption_617046; body: JsonNode): Recallable =
  ## describeTagOption
  ## Gets information about the specified TagOption.
  ##   body: JObject (required)
  var body_617060 = newJObject()
  if body != nil:
    body_617060 = body
  result = call_617059.call(nil, nil, nil, nil, body_617060)

var describeTagOption* = Call_DescribeTagOption_617046(name: "describeTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption",
    validator: validate_DescribeTagOption_617047, base: "/",
    url: url_DescribeTagOption_617048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSOrganizationsAccess_617061 = ref object of OpenApiRestCall_615866
proc url_DisableAWSOrganizationsAccess_617063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableAWSOrganizationsAccess_617062(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617064 = header.getOrDefault("X-Amz-Date")
  valid_617064 = validateParameter(valid_617064, JString, required = false,
                                 default = nil)
  if valid_617064 != nil:
    section.add "X-Amz-Date", valid_617064
  var valid_617065 = header.getOrDefault("X-Amz-Security-Token")
  valid_617065 = validateParameter(valid_617065, JString, required = false,
                                 default = nil)
  if valid_617065 != nil:
    section.add "X-Amz-Security-Token", valid_617065
  var valid_617066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617066 = validateParameter(valid_617066, JString, required = false,
                                 default = nil)
  if valid_617066 != nil:
    section.add "X-Amz-Content-Sha256", valid_617066
  var valid_617067 = header.getOrDefault("X-Amz-Algorithm")
  valid_617067 = validateParameter(valid_617067, JString, required = false,
                                 default = nil)
  if valid_617067 != nil:
    section.add "X-Amz-Algorithm", valid_617067
  var valid_617068 = header.getOrDefault("X-Amz-Signature")
  valid_617068 = validateParameter(valid_617068, JString, required = false,
                                 default = nil)
  if valid_617068 != nil:
    section.add "X-Amz-Signature", valid_617068
  var valid_617069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617069 = validateParameter(valid_617069, JString, required = false,
                                 default = nil)
  if valid_617069 != nil:
    section.add "X-Amz-SignedHeaders", valid_617069
  var valid_617070 = header.getOrDefault("X-Amz-Target")
  valid_617070 = validateParameter(valid_617070, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"))
  if valid_617070 != nil:
    section.add "X-Amz-Target", valid_617070
  var valid_617071 = header.getOrDefault("X-Amz-Credential")
  valid_617071 = validateParameter(valid_617071, JString, required = false,
                                 default = nil)
  if valid_617071 != nil:
    section.add "X-Amz-Credential", valid_617071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617073: Call_DisableAWSOrganizationsAccess_617061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ## 
  let valid = call_617073.validator(path, query, header, formData, body)
  let scheme = call_617073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617073.url(scheme.get, call_617073.host, call_617073.base,
                         call_617073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617073, url, valid)

proc call*(call_617074: Call_DisableAWSOrganizationsAccess_617061; body: JsonNode): Recallable =
  ## disableAWSOrganizationsAccess
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_617075 = newJObject()
  if body != nil:
    body_617075 = body
  result = call_617074.call(nil, nil, nil, nil, body_617075)

var disableAWSOrganizationsAccess* = Call_DisableAWSOrganizationsAccess_617061(
    name: "disableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess",
    validator: validate_DisableAWSOrganizationsAccess_617062, base: "/",
    url: url_DisableAWSOrganizationsAccess_617063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateBudgetFromResource_617076 = ref object of OpenApiRestCall_615866
proc url_DisassociateBudgetFromResource_617078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateBudgetFromResource_617077(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617079 = header.getOrDefault("X-Amz-Date")
  valid_617079 = validateParameter(valid_617079, JString, required = false,
                                 default = nil)
  if valid_617079 != nil:
    section.add "X-Amz-Date", valid_617079
  var valid_617080 = header.getOrDefault("X-Amz-Security-Token")
  valid_617080 = validateParameter(valid_617080, JString, required = false,
                                 default = nil)
  if valid_617080 != nil:
    section.add "X-Amz-Security-Token", valid_617080
  var valid_617081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617081 = validateParameter(valid_617081, JString, required = false,
                                 default = nil)
  if valid_617081 != nil:
    section.add "X-Amz-Content-Sha256", valid_617081
  var valid_617082 = header.getOrDefault("X-Amz-Algorithm")
  valid_617082 = validateParameter(valid_617082, JString, required = false,
                                 default = nil)
  if valid_617082 != nil:
    section.add "X-Amz-Algorithm", valid_617082
  var valid_617083 = header.getOrDefault("X-Amz-Signature")
  valid_617083 = validateParameter(valid_617083, JString, required = false,
                                 default = nil)
  if valid_617083 != nil:
    section.add "X-Amz-Signature", valid_617083
  var valid_617084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617084 = validateParameter(valid_617084, JString, required = false,
                                 default = nil)
  if valid_617084 != nil:
    section.add "X-Amz-SignedHeaders", valid_617084
  var valid_617085 = header.getOrDefault("X-Amz-Target")
  valid_617085 = validateParameter(valid_617085, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateBudgetFromResource"))
  if valid_617085 != nil:
    section.add "X-Amz-Target", valid_617085
  var valid_617086 = header.getOrDefault("X-Amz-Credential")
  valid_617086 = validateParameter(valid_617086, JString, required = false,
                                 default = nil)
  if valid_617086 != nil:
    section.add "X-Amz-Credential", valid_617086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617088: Call_DisassociateBudgetFromResource_617076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified budget from the specified resource.
  ## 
  let valid = call_617088.validator(path, query, header, formData, body)
  let scheme = call_617088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617088.url(scheme.get, call_617088.host, call_617088.base,
                         call_617088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617088, url, valid)

proc call*(call_617089: Call_DisassociateBudgetFromResource_617076; body: JsonNode): Recallable =
  ## disassociateBudgetFromResource
  ## Disassociates the specified budget from the specified resource.
  ##   body: JObject (required)
  var body_617090 = newJObject()
  if body != nil:
    body_617090 = body
  result = call_617089.call(nil, nil, nil, nil, body_617090)

var disassociateBudgetFromResource* = Call_DisassociateBudgetFromResource_617076(
    name: "disassociateBudgetFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource",
    validator: validate_DisassociateBudgetFromResource_617077, base: "/",
    url: url_DisassociateBudgetFromResource_617078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePrincipalFromPortfolio_617091 = ref object of OpenApiRestCall_615866
proc url_DisassociatePrincipalFromPortfolio_617093(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociatePrincipalFromPortfolio_617092(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617094 = header.getOrDefault("X-Amz-Date")
  valid_617094 = validateParameter(valid_617094, JString, required = false,
                                 default = nil)
  if valid_617094 != nil:
    section.add "X-Amz-Date", valid_617094
  var valid_617095 = header.getOrDefault("X-Amz-Security-Token")
  valid_617095 = validateParameter(valid_617095, JString, required = false,
                                 default = nil)
  if valid_617095 != nil:
    section.add "X-Amz-Security-Token", valid_617095
  var valid_617096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617096 = validateParameter(valid_617096, JString, required = false,
                                 default = nil)
  if valid_617096 != nil:
    section.add "X-Amz-Content-Sha256", valid_617096
  var valid_617097 = header.getOrDefault("X-Amz-Algorithm")
  valid_617097 = validateParameter(valid_617097, JString, required = false,
                                 default = nil)
  if valid_617097 != nil:
    section.add "X-Amz-Algorithm", valid_617097
  var valid_617098 = header.getOrDefault("X-Amz-Signature")
  valid_617098 = validateParameter(valid_617098, JString, required = false,
                                 default = nil)
  if valid_617098 != nil:
    section.add "X-Amz-Signature", valid_617098
  var valid_617099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617099 = validateParameter(valid_617099, JString, required = false,
                                 default = nil)
  if valid_617099 != nil:
    section.add "X-Amz-SignedHeaders", valid_617099
  var valid_617100 = header.getOrDefault("X-Amz-Target")
  valid_617100 = validateParameter(valid_617100, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"))
  if valid_617100 != nil:
    section.add "X-Amz-Target", valid_617100
  var valid_617101 = header.getOrDefault("X-Amz-Credential")
  valid_617101 = validateParameter(valid_617101, JString, required = false,
                                 default = nil)
  if valid_617101 != nil:
    section.add "X-Amz-Credential", valid_617101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617103: Call_DisassociatePrincipalFromPortfolio_617091;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ## 
  let valid = call_617103.validator(path, query, header, formData, body)
  let scheme = call_617103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617103.url(scheme.get, call_617103.host, call_617103.base,
                         call_617103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617103, url, valid)

proc call*(call_617104: Call_DisassociatePrincipalFromPortfolio_617091;
          body: JsonNode): Recallable =
  ## disassociatePrincipalFromPortfolio
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ##   body: JObject (required)
  var body_617105 = newJObject()
  if body != nil:
    body_617105 = body
  result = call_617104.call(nil, nil, nil, nil, body_617105)

var disassociatePrincipalFromPortfolio* = Call_DisassociatePrincipalFromPortfolio_617091(
    name: "disassociatePrincipalFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio",
    validator: validate_DisassociatePrincipalFromPortfolio_617092, base: "/",
    url: url_DisassociatePrincipalFromPortfolio_617093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateProductFromPortfolio_617106 = ref object of OpenApiRestCall_615866
proc url_DisassociateProductFromPortfolio_617108(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateProductFromPortfolio_617107(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617109 = header.getOrDefault("X-Amz-Date")
  valid_617109 = validateParameter(valid_617109, JString, required = false,
                                 default = nil)
  if valid_617109 != nil:
    section.add "X-Amz-Date", valid_617109
  var valid_617110 = header.getOrDefault("X-Amz-Security-Token")
  valid_617110 = validateParameter(valid_617110, JString, required = false,
                                 default = nil)
  if valid_617110 != nil:
    section.add "X-Amz-Security-Token", valid_617110
  var valid_617111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617111 = validateParameter(valid_617111, JString, required = false,
                                 default = nil)
  if valid_617111 != nil:
    section.add "X-Amz-Content-Sha256", valid_617111
  var valid_617112 = header.getOrDefault("X-Amz-Algorithm")
  valid_617112 = validateParameter(valid_617112, JString, required = false,
                                 default = nil)
  if valid_617112 != nil:
    section.add "X-Amz-Algorithm", valid_617112
  var valid_617113 = header.getOrDefault("X-Amz-Signature")
  valid_617113 = validateParameter(valid_617113, JString, required = false,
                                 default = nil)
  if valid_617113 != nil:
    section.add "X-Amz-Signature", valid_617113
  var valid_617114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617114 = validateParameter(valid_617114, JString, required = false,
                                 default = nil)
  if valid_617114 != nil:
    section.add "X-Amz-SignedHeaders", valid_617114
  var valid_617115 = header.getOrDefault("X-Amz-Target")
  valid_617115 = validateParameter(valid_617115, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateProductFromPortfolio"))
  if valid_617115 != nil:
    section.add "X-Amz-Target", valid_617115
  var valid_617116 = header.getOrDefault("X-Amz-Credential")
  valid_617116 = validateParameter(valid_617116, JString, required = false,
                                 default = nil)
  if valid_617116 != nil:
    section.add "X-Amz-Credential", valid_617116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617118: Call_DisassociateProductFromPortfolio_617106;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified product from the specified portfolio. 
  ## 
  let valid = call_617118.validator(path, query, header, formData, body)
  let scheme = call_617118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617118.url(scheme.get, call_617118.host, call_617118.base,
                         call_617118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617118, url, valid)

proc call*(call_617119: Call_DisassociateProductFromPortfolio_617106;
          body: JsonNode): Recallable =
  ## disassociateProductFromPortfolio
  ## Disassociates the specified product from the specified portfolio. 
  ##   body: JObject (required)
  var body_617120 = newJObject()
  if body != nil:
    body_617120 = body
  result = call_617119.call(nil, nil, nil, nil, body_617120)

var disassociateProductFromPortfolio* = Call_DisassociateProductFromPortfolio_617106(
    name: "disassociateProductFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio",
    validator: validate_DisassociateProductFromPortfolio_617107, base: "/",
    url: url_DisassociateProductFromPortfolio_617108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceActionFromProvisioningArtifact_617121 = ref object of OpenApiRestCall_615866
proc url_DisassociateServiceActionFromProvisioningArtifact_617123(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceActionFromProvisioningArtifact_617122(
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617124 = header.getOrDefault("X-Amz-Date")
  valid_617124 = validateParameter(valid_617124, JString, required = false,
                                 default = nil)
  if valid_617124 != nil:
    section.add "X-Amz-Date", valid_617124
  var valid_617125 = header.getOrDefault("X-Amz-Security-Token")
  valid_617125 = validateParameter(valid_617125, JString, required = false,
                                 default = nil)
  if valid_617125 != nil:
    section.add "X-Amz-Security-Token", valid_617125
  var valid_617126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617126 = validateParameter(valid_617126, JString, required = false,
                                 default = nil)
  if valid_617126 != nil:
    section.add "X-Amz-Content-Sha256", valid_617126
  var valid_617127 = header.getOrDefault("X-Amz-Algorithm")
  valid_617127 = validateParameter(valid_617127, JString, required = false,
                                 default = nil)
  if valid_617127 != nil:
    section.add "X-Amz-Algorithm", valid_617127
  var valid_617128 = header.getOrDefault("X-Amz-Signature")
  valid_617128 = validateParameter(valid_617128, JString, required = false,
                                 default = nil)
  if valid_617128 != nil:
    section.add "X-Amz-Signature", valid_617128
  var valid_617129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617129 = validateParameter(valid_617129, JString, required = false,
                                 default = nil)
  if valid_617129 != nil:
    section.add "X-Amz-SignedHeaders", valid_617129
  var valid_617130 = header.getOrDefault("X-Amz-Target")
  valid_617130 = validateParameter(valid_617130, JString, required = true, default = newJString("AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"))
  if valid_617130 != nil:
    section.add "X-Amz-Target", valid_617130
  var valid_617131 = header.getOrDefault("X-Amz-Credential")
  valid_617131 = validateParameter(valid_617131, JString, required = false,
                                 default = nil)
  if valid_617131 != nil:
    section.add "X-Amz-Credential", valid_617131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617133: Call_DisassociateServiceActionFromProvisioningArtifact_617121;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ## 
  let valid = call_617133.validator(path, query, header, formData, body)
  let scheme = call_617133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617133.url(scheme.get, call_617133.host, call_617133.base,
                         call_617133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617133, url, valid)

proc call*(call_617134: Call_DisassociateServiceActionFromProvisioningArtifact_617121;
          body: JsonNode): Recallable =
  ## disassociateServiceActionFromProvisioningArtifact
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_617135 = newJObject()
  if body != nil:
    body_617135 = body
  result = call_617134.call(nil, nil, nil, nil, body_617135)

var disassociateServiceActionFromProvisioningArtifact* = Call_DisassociateServiceActionFromProvisioningArtifact_617121(
    name: "disassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact",
    validator: validate_DisassociateServiceActionFromProvisioningArtifact_617122,
    base: "/", url: url_DisassociateServiceActionFromProvisioningArtifact_617123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTagOptionFromResource_617136 = ref object of OpenApiRestCall_615866
proc url_DisassociateTagOptionFromResource_617138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateTagOptionFromResource_617137(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617139 = header.getOrDefault("X-Amz-Date")
  valid_617139 = validateParameter(valid_617139, JString, required = false,
                                 default = nil)
  if valid_617139 != nil:
    section.add "X-Amz-Date", valid_617139
  var valid_617140 = header.getOrDefault("X-Amz-Security-Token")
  valid_617140 = validateParameter(valid_617140, JString, required = false,
                                 default = nil)
  if valid_617140 != nil:
    section.add "X-Amz-Security-Token", valid_617140
  var valid_617141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617141 = validateParameter(valid_617141, JString, required = false,
                                 default = nil)
  if valid_617141 != nil:
    section.add "X-Amz-Content-Sha256", valid_617141
  var valid_617142 = header.getOrDefault("X-Amz-Algorithm")
  valid_617142 = validateParameter(valid_617142, JString, required = false,
                                 default = nil)
  if valid_617142 != nil:
    section.add "X-Amz-Algorithm", valid_617142
  var valid_617143 = header.getOrDefault("X-Amz-Signature")
  valid_617143 = validateParameter(valid_617143, JString, required = false,
                                 default = nil)
  if valid_617143 != nil:
    section.add "X-Amz-Signature", valid_617143
  var valid_617144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617144 = validateParameter(valid_617144, JString, required = false,
                                 default = nil)
  if valid_617144 != nil:
    section.add "X-Amz-SignedHeaders", valid_617144
  var valid_617145 = header.getOrDefault("X-Amz-Target")
  valid_617145 = validateParameter(valid_617145, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateTagOptionFromResource"))
  if valid_617145 != nil:
    section.add "X-Amz-Target", valid_617145
  var valid_617146 = header.getOrDefault("X-Amz-Credential")
  valid_617146 = validateParameter(valid_617146, JString, required = false,
                                 default = nil)
  if valid_617146 != nil:
    section.add "X-Amz-Credential", valid_617146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617148: Call_DisassociateTagOptionFromResource_617136;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified TagOption from the specified resource.
  ## 
  let valid = call_617148.validator(path, query, header, formData, body)
  let scheme = call_617148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617148.url(scheme.get, call_617148.host, call_617148.base,
                         call_617148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617148, url, valid)

proc call*(call_617149: Call_DisassociateTagOptionFromResource_617136;
          body: JsonNode): Recallable =
  ## disassociateTagOptionFromResource
  ## Disassociates the specified TagOption from the specified resource.
  ##   body: JObject (required)
  var body_617150 = newJObject()
  if body != nil:
    body_617150 = body
  result = call_617149.call(nil, nil, nil, nil, body_617150)

var disassociateTagOptionFromResource* = Call_DisassociateTagOptionFromResource_617136(
    name: "disassociateTagOptionFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource",
    validator: validate_DisassociateTagOptionFromResource_617137, base: "/",
    url: url_DisassociateTagOptionFromResource_617138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSOrganizationsAccess_617151 = ref object of OpenApiRestCall_615866
proc url_EnableAWSOrganizationsAccess_617153(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableAWSOrganizationsAccess_617152(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617154 = header.getOrDefault("X-Amz-Date")
  valid_617154 = validateParameter(valid_617154, JString, required = false,
                                 default = nil)
  if valid_617154 != nil:
    section.add "X-Amz-Date", valid_617154
  var valid_617155 = header.getOrDefault("X-Amz-Security-Token")
  valid_617155 = validateParameter(valid_617155, JString, required = false,
                                 default = nil)
  if valid_617155 != nil:
    section.add "X-Amz-Security-Token", valid_617155
  var valid_617156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617156 = validateParameter(valid_617156, JString, required = false,
                                 default = nil)
  if valid_617156 != nil:
    section.add "X-Amz-Content-Sha256", valid_617156
  var valid_617157 = header.getOrDefault("X-Amz-Algorithm")
  valid_617157 = validateParameter(valid_617157, JString, required = false,
                                 default = nil)
  if valid_617157 != nil:
    section.add "X-Amz-Algorithm", valid_617157
  var valid_617158 = header.getOrDefault("X-Amz-Signature")
  valid_617158 = validateParameter(valid_617158, JString, required = false,
                                 default = nil)
  if valid_617158 != nil:
    section.add "X-Amz-Signature", valid_617158
  var valid_617159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617159 = validateParameter(valid_617159, JString, required = false,
                                 default = nil)
  if valid_617159 != nil:
    section.add "X-Amz-SignedHeaders", valid_617159
  var valid_617160 = header.getOrDefault("X-Amz-Target")
  valid_617160 = validateParameter(valid_617160, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"))
  if valid_617160 != nil:
    section.add "X-Amz-Target", valid_617160
  var valid_617161 = header.getOrDefault("X-Amz-Credential")
  valid_617161 = validateParameter(valid_617161, JString, required = false,
                                 default = nil)
  if valid_617161 != nil:
    section.add "X-Amz-Credential", valid_617161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617163: Call_EnableAWSOrganizationsAccess_617151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ## 
  let valid = call_617163.validator(path, query, header, formData, body)
  let scheme = call_617163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617163.url(scheme.get, call_617163.host, call_617163.base,
                         call_617163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617163, url, valid)

proc call*(call_617164: Call_EnableAWSOrganizationsAccess_617151; body: JsonNode): Recallable =
  ## enableAWSOrganizationsAccess
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ##   body: JObject (required)
  var body_617165 = newJObject()
  if body != nil:
    body_617165 = body
  result = call_617164.call(nil, nil, nil, nil, body_617165)

var enableAWSOrganizationsAccess* = Call_EnableAWSOrganizationsAccess_617151(
    name: "enableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess",
    validator: validate_EnableAWSOrganizationsAccess_617152, base: "/",
    url: url_EnableAWSOrganizationsAccess_617153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductPlan_617166 = ref object of OpenApiRestCall_615866
proc url_ExecuteProvisionedProductPlan_617168(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteProvisionedProductPlan_617167(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617169 = header.getOrDefault("X-Amz-Date")
  valid_617169 = validateParameter(valid_617169, JString, required = false,
                                 default = nil)
  if valid_617169 != nil:
    section.add "X-Amz-Date", valid_617169
  var valid_617170 = header.getOrDefault("X-Amz-Security-Token")
  valid_617170 = validateParameter(valid_617170, JString, required = false,
                                 default = nil)
  if valid_617170 != nil:
    section.add "X-Amz-Security-Token", valid_617170
  var valid_617171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617171 = validateParameter(valid_617171, JString, required = false,
                                 default = nil)
  if valid_617171 != nil:
    section.add "X-Amz-Content-Sha256", valid_617171
  var valid_617172 = header.getOrDefault("X-Amz-Algorithm")
  valid_617172 = validateParameter(valid_617172, JString, required = false,
                                 default = nil)
  if valid_617172 != nil:
    section.add "X-Amz-Algorithm", valid_617172
  var valid_617173 = header.getOrDefault("X-Amz-Signature")
  valid_617173 = validateParameter(valid_617173, JString, required = false,
                                 default = nil)
  if valid_617173 != nil:
    section.add "X-Amz-Signature", valid_617173
  var valid_617174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617174 = validateParameter(valid_617174, JString, required = false,
                                 default = nil)
  if valid_617174 != nil:
    section.add "X-Amz-SignedHeaders", valid_617174
  var valid_617175 = header.getOrDefault("X-Amz-Target")
  valid_617175 = validateParameter(valid_617175, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"))
  if valid_617175 != nil:
    section.add "X-Amz-Target", valid_617175
  var valid_617176 = header.getOrDefault("X-Amz-Credential")
  valid_617176 = validateParameter(valid_617176, JString, required = false,
                                 default = nil)
  if valid_617176 != nil:
    section.add "X-Amz-Credential", valid_617176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617178: Call_ExecuteProvisionedProductPlan_617166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ## 
  let valid = call_617178.validator(path, query, header, formData, body)
  let scheme = call_617178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617178.url(scheme.get, call_617178.host, call_617178.base,
                         call_617178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617178, url, valid)

proc call*(call_617179: Call_ExecuteProvisionedProductPlan_617166; body: JsonNode): Recallable =
  ## executeProvisionedProductPlan
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_617180 = newJObject()
  if body != nil:
    body_617180 = body
  result = call_617179.call(nil, nil, nil, nil, body_617180)

var executeProvisionedProductPlan* = Call_ExecuteProvisionedProductPlan_617166(
    name: "executeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan",
    validator: validate_ExecuteProvisionedProductPlan_617167, base: "/",
    url: url_ExecuteProvisionedProductPlan_617168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductServiceAction_617181 = ref object of OpenApiRestCall_615866
proc url_ExecuteProvisionedProductServiceAction_617183(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteProvisionedProductServiceAction_617182(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617184 = header.getOrDefault("X-Amz-Date")
  valid_617184 = validateParameter(valid_617184, JString, required = false,
                                 default = nil)
  if valid_617184 != nil:
    section.add "X-Amz-Date", valid_617184
  var valid_617185 = header.getOrDefault("X-Amz-Security-Token")
  valid_617185 = validateParameter(valid_617185, JString, required = false,
                                 default = nil)
  if valid_617185 != nil:
    section.add "X-Amz-Security-Token", valid_617185
  var valid_617186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617186 = validateParameter(valid_617186, JString, required = false,
                                 default = nil)
  if valid_617186 != nil:
    section.add "X-Amz-Content-Sha256", valid_617186
  var valid_617187 = header.getOrDefault("X-Amz-Algorithm")
  valid_617187 = validateParameter(valid_617187, JString, required = false,
                                 default = nil)
  if valid_617187 != nil:
    section.add "X-Amz-Algorithm", valid_617187
  var valid_617188 = header.getOrDefault("X-Amz-Signature")
  valid_617188 = validateParameter(valid_617188, JString, required = false,
                                 default = nil)
  if valid_617188 != nil:
    section.add "X-Amz-Signature", valid_617188
  var valid_617189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617189 = validateParameter(valid_617189, JString, required = false,
                                 default = nil)
  if valid_617189 != nil:
    section.add "X-Amz-SignedHeaders", valid_617189
  var valid_617190 = header.getOrDefault("X-Amz-Target")
  valid_617190 = validateParameter(valid_617190, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"))
  if valid_617190 != nil:
    section.add "X-Amz-Target", valid_617190
  var valid_617191 = header.getOrDefault("X-Amz-Credential")
  valid_617191 = validateParameter(valid_617191, JString, required = false,
                                 default = nil)
  if valid_617191 != nil:
    section.add "X-Amz-Credential", valid_617191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617193: Call_ExecuteProvisionedProductServiceAction_617181;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Executes a self-service action against a provisioned product.
  ## 
  let valid = call_617193.validator(path, query, header, formData, body)
  let scheme = call_617193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617193.url(scheme.get, call_617193.host, call_617193.base,
                         call_617193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617193, url, valid)

proc call*(call_617194: Call_ExecuteProvisionedProductServiceAction_617181;
          body: JsonNode): Recallable =
  ## executeProvisionedProductServiceAction
  ## Executes a self-service action against a provisioned product.
  ##   body: JObject (required)
  var body_617195 = newJObject()
  if body != nil:
    body_617195 = body
  result = call_617194.call(nil, nil, nil, nil, body_617195)

var executeProvisionedProductServiceAction* = Call_ExecuteProvisionedProductServiceAction_617181(
    name: "executeProvisionedProductServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction",
    validator: validate_ExecuteProvisionedProductServiceAction_617182, base: "/",
    url: url_ExecuteProvisionedProductServiceAction_617183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSOrganizationsAccessStatus_617196 = ref object of OpenApiRestCall_615866
proc url_GetAWSOrganizationsAccessStatus_617198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAWSOrganizationsAccessStatus_617197(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617199 = header.getOrDefault("X-Amz-Date")
  valid_617199 = validateParameter(valid_617199, JString, required = false,
                                 default = nil)
  if valid_617199 != nil:
    section.add "X-Amz-Date", valid_617199
  var valid_617200 = header.getOrDefault("X-Amz-Security-Token")
  valid_617200 = validateParameter(valid_617200, JString, required = false,
                                 default = nil)
  if valid_617200 != nil:
    section.add "X-Amz-Security-Token", valid_617200
  var valid_617201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617201 = validateParameter(valid_617201, JString, required = false,
                                 default = nil)
  if valid_617201 != nil:
    section.add "X-Amz-Content-Sha256", valid_617201
  var valid_617202 = header.getOrDefault("X-Amz-Algorithm")
  valid_617202 = validateParameter(valid_617202, JString, required = false,
                                 default = nil)
  if valid_617202 != nil:
    section.add "X-Amz-Algorithm", valid_617202
  var valid_617203 = header.getOrDefault("X-Amz-Signature")
  valid_617203 = validateParameter(valid_617203, JString, required = false,
                                 default = nil)
  if valid_617203 != nil:
    section.add "X-Amz-Signature", valid_617203
  var valid_617204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617204 = validateParameter(valid_617204, JString, required = false,
                                 default = nil)
  if valid_617204 != nil:
    section.add "X-Amz-SignedHeaders", valid_617204
  var valid_617205 = header.getOrDefault("X-Amz-Target")
  valid_617205 = validateParameter(valid_617205, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"))
  if valid_617205 != nil:
    section.add "X-Amz-Target", valid_617205
  var valid_617206 = header.getOrDefault("X-Amz-Credential")
  valid_617206 = validateParameter(valid_617206, JString, required = false,
                                 default = nil)
  if valid_617206 != nil:
    section.add "X-Amz-Credential", valid_617206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617208: Call_GetAWSOrganizationsAccessStatus_617196;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ## 
  let valid = call_617208.validator(path, query, header, formData, body)
  let scheme = call_617208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617208.url(scheme.get, call_617208.host, call_617208.base,
                         call_617208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617208, url, valid)

proc call*(call_617209: Call_GetAWSOrganizationsAccessStatus_617196; body: JsonNode): Recallable =
  ## getAWSOrganizationsAccessStatus
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_617210 = newJObject()
  if body != nil:
    body_617210 = body
  result = call_617209.call(nil, nil, nil, nil, body_617210)

var getAWSOrganizationsAccessStatus* = Call_GetAWSOrganizationsAccessStatus_617196(
    name: "getAWSOrganizationsAccessStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus",
    validator: validate_GetAWSOrganizationsAccessStatus_617197, base: "/",
    url: url_GetAWSOrganizationsAccessStatus_617198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAcceptedPortfolioShares_617211 = ref object of OpenApiRestCall_615866
proc url_ListAcceptedPortfolioShares_617213(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAcceptedPortfolioShares_617212(path: JsonNode; query: JsonNode;
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
  var valid_617214 = query.getOrDefault("PageSize")
  valid_617214 = validateParameter(valid_617214, JString, required = false,
                                 default = nil)
  if valid_617214 != nil:
    section.add "PageSize", valid_617214
  var valid_617215 = query.getOrDefault("PageToken")
  valid_617215 = validateParameter(valid_617215, JString, required = false,
                                 default = nil)
  if valid_617215 != nil:
    section.add "PageToken", valid_617215
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617216 = header.getOrDefault("X-Amz-Date")
  valid_617216 = validateParameter(valid_617216, JString, required = false,
                                 default = nil)
  if valid_617216 != nil:
    section.add "X-Amz-Date", valid_617216
  var valid_617217 = header.getOrDefault("X-Amz-Security-Token")
  valid_617217 = validateParameter(valid_617217, JString, required = false,
                                 default = nil)
  if valid_617217 != nil:
    section.add "X-Amz-Security-Token", valid_617217
  var valid_617218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617218 = validateParameter(valid_617218, JString, required = false,
                                 default = nil)
  if valid_617218 != nil:
    section.add "X-Amz-Content-Sha256", valid_617218
  var valid_617219 = header.getOrDefault("X-Amz-Algorithm")
  valid_617219 = validateParameter(valid_617219, JString, required = false,
                                 default = nil)
  if valid_617219 != nil:
    section.add "X-Amz-Algorithm", valid_617219
  var valid_617220 = header.getOrDefault("X-Amz-Signature")
  valid_617220 = validateParameter(valid_617220, JString, required = false,
                                 default = nil)
  if valid_617220 != nil:
    section.add "X-Amz-Signature", valid_617220
  var valid_617221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617221 = validateParameter(valid_617221, JString, required = false,
                                 default = nil)
  if valid_617221 != nil:
    section.add "X-Amz-SignedHeaders", valid_617221
  var valid_617222 = header.getOrDefault("X-Amz-Target")
  valid_617222 = validateParameter(valid_617222, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListAcceptedPortfolioShares"))
  if valid_617222 != nil:
    section.add "X-Amz-Target", valid_617222
  var valid_617223 = header.getOrDefault("X-Amz-Credential")
  valid_617223 = validateParameter(valid_617223, JString, required = false,
                                 default = nil)
  if valid_617223 != nil:
    section.add "X-Amz-Credential", valid_617223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617225: Call_ListAcceptedPortfolioShares_617211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  let valid = call_617225.validator(path, query, header, formData, body)
  let scheme = call_617225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617225.url(scheme.get, call_617225.host, call_617225.base,
                         call_617225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617225, url, valid)

proc call*(call_617226: Call_ListAcceptedPortfolioShares_617211; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listAcceptedPortfolioShares
  ## Lists all portfolios for which sharing was accepted by this account.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617227 = newJObject()
  var body_617228 = newJObject()
  add(query_617227, "PageSize", newJString(PageSize))
  add(query_617227, "PageToken", newJString(PageToken))
  if body != nil:
    body_617228 = body
  result = call_617226.call(nil, query_617227, nil, nil, body_617228)

var listAcceptedPortfolioShares* = Call_ListAcceptedPortfolioShares_617211(
    name: "listAcceptedPortfolioShares", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares",
    validator: validate_ListAcceptedPortfolioShares_617212, base: "/",
    url: url_ListAcceptedPortfolioShares_617213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBudgetsForResource_617230 = ref object of OpenApiRestCall_615866
proc url_ListBudgetsForResource_617232(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBudgetsForResource_617231(path: JsonNode; query: JsonNode;
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
  var valid_617233 = query.getOrDefault("PageSize")
  valid_617233 = validateParameter(valid_617233, JString, required = false,
                                 default = nil)
  if valid_617233 != nil:
    section.add "PageSize", valid_617233
  var valid_617234 = query.getOrDefault("PageToken")
  valid_617234 = validateParameter(valid_617234, JString, required = false,
                                 default = nil)
  if valid_617234 != nil:
    section.add "PageToken", valid_617234
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617235 = header.getOrDefault("X-Amz-Date")
  valid_617235 = validateParameter(valid_617235, JString, required = false,
                                 default = nil)
  if valid_617235 != nil:
    section.add "X-Amz-Date", valid_617235
  var valid_617236 = header.getOrDefault("X-Amz-Security-Token")
  valid_617236 = validateParameter(valid_617236, JString, required = false,
                                 default = nil)
  if valid_617236 != nil:
    section.add "X-Amz-Security-Token", valid_617236
  var valid_617237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617237 = validateParameter(valid_617237, JString, required = false,
                                 default = nil)
  if valid_617237 != nil:
    section.add "X-Amz-Content-Sha256", valid_617237
  var valid_617238 = header.getOrDefault("X-Amz-Algorithm")
  valid_617238 = validateParameter(valid_617238, JString, required = false,
                                 default = nil)
  if valid_617238 != nil:
    section.add "X-Amz-Algorithm", valid_617238
  var valid_617239 = header.getOrDefault("X-Amz-Signature")
  valid_617239 = validateParameter(valid_617239, JString, required = false,
                                 default = nil)
  if valid_617239 != nil:
    section.add "X-Amz-Signature", valid_617239
  var valid_617240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617240 = validateParameter(valid_617240, JString, required = false,
                                 default = nil)
  if valid_617240 != nil:
    section.add "X-Amz-SignedHeaders", valid_617240
  var valid_617241 = header.getOrDefault("X-Amz-Target")
  valid_617241 = validateParameter(valid_617241, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListBudgetsForResource"))
  if valid_617241 != nil:
    section.add "X-Amz-Target", valid_617241
  var valid_617242 = header.getOrDefault("X-Amz-Credential")
  valid_617242 = validateParameter(valid_617242, JString, required = false,
                                 default = nil)
  if valid_617242 != nil:
    section.add "X-Amz-Credential", valid_617242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617244: Call_ListBudgetsForResource_617230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the budgets associated to the specified resource.
  ## 
  let valid = call_617244.validator(path, query, header, formData, body)
  let scheme = call_617244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617244.url(scheme.get, call_617244.host, call_617244.base,
                         call_617244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617244, url, valid)

proc call*(call_617245: Call_ListBudgetsForResource_617230; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listBudgetsForResource
  ## Lists all the budgets associated to the specified resource.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617246 = newJObject()
  var body_617247 = newJObject()
  add(query_617246, "PageSize", newJString(PageSize))
  add(query_617246, "PageToken", newJString(PageToken))
  if body != nil:
    body_617247 = body
  result = call_617245.call(nil, query_617246, nil, nil, body_617247)

var listBudgetsForResource* = Call_ListBudgetsForResource_617230(
    name: "listBudgetsForResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource",
    validator: validate_ListBudgetsForResource_617231, base: "/",
    url: url_ListBudgetsForResource_617232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConstraintsForPortfolio_617248 = ref object of OpenApiRestCall_615866
proc url_ListConstraintsForPortfolio_617250(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConstraintsForPortfolio_617249(path: JsonNode; query: JsonNode;
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
  var valid_617251 = query.getOrDefault("PageSize")
  valid_617251 = validateParameter(valid_617251, JString, required = false,
                                 default = nil)
  if valid_617251 != nil:
    section.add "PageSize", valid_617251
  var valid_617252 = query.getOrDefault("PageToken")
  valid_617252 = validateParameter(valid_617252, JString, required = false,
                                 default = nil)
  if valid_617252 != nil:
    section.add "PageToken", valid_617252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617253 = header.getOrDefault("X-Amz-Date")
  valid_617253 = validateParameter(valid_617253, JString, required = false,
                                 default = nil)
  if valid_617253 != nil:
    section.add "X-Amz-Date", valid_617253
  var valid_617254 = header.getOrDefault("X-Amz-Security-Token")
  valid_617254 = validateParameter(valid_617254, JString, required = false,
                                 default = nil)
  if valid_617254 != nil:
    section.add "X-Amz-Security-Token", valid_617254
  var valid_617255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617255 = validateParameter(valid_617255, JString, required = false,
                                 default = nil)
  if valid_617255 != nil:
    section.add "X-Amz-Content-Sha256", valid_617255
  var valid_617256 = header.getOrDefault("X-Amz-Algorithm")
  valid_617256 = validateParameter(valid_617256, JString, required = false,
                                 default = nil)
  if valid_617256 != nil:
    section.add "X-Amz-Algorithm", valid_617256
  var valid_617257 = header.getOrDefault("X-Amz-Signature")
  valid_617257 = validateParameter(valid_617257, JString, required = false,
                                 default = nil)
  if valid_617257 != nil:
    section.add "X-Amz-Signature", valid_617257
  var valid_617258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617258 = validateParameter(valid_617258, JString, required = false,
                                 default = nil)
  if valid_617258 != nil:
    section.add "X-Amz-SignedHeaders", valid_617258
  var valid_617259 = header.getOrDefault("X-Amz-Target")
  valid_617259 = validateParameter(valid_617259, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListConstraintsForPortfolio"))
  if valid_617259 != nil:
    section.add "X-Amz-Target", valid_617259
  var valid_617260 = header.getOrDefault("X-Amz-Credential")
  valid_617260 = validateParameter(valid_617260, JString, required = false,
                                 default = nil)
  if valid_617260 != nil:
    section.add "X-Amz-Credential", valid_617260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617262: Call_ListConstraintsForPortfolio_617248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  let valid = call_617262.validator(path, query, header, formData, body)
  let scheme = call_617262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617262.url(scheme.get, call_617262.host, call_617262.base,
                         call_617262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617262, url, valid)

proc call*(call_617263: Call_ListConstraintsForPortfolio_617248; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listConstraintsForPortfolio
  ## Lists the constraints for the specified portfolio and product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617264 = newJObject()
  var body_617265 = newJObject()
  add(query_617264, "PageSize", newJString(PageSize))
  add(query_617264, "PageToken", newJString(PageToken))
  if body != nil:
    body_617265 = body
  result = call_617263.call(nil, query_617264, nil, nil, body_617265)

var listConstraintsForPortfolio* = Call_ListConstraintsForPortfolio_617248(
    name: "listConstraintsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio",
    validator: validate_ListConstraintsForPortfolio_617249, base: "/",
    url: url_ListConstraintsForPortfolio_617250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLaunchPaths_617266 = ref object of OpenApiRestCall_615866
proc url_ListLaunchPaths_617268(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLaunchPaths_617267(path: JsonNode; query: JsonNode;
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
  var valid_617269 = query.getOrDefault("PageSize")
  valid_617269 = validateParameter(valid_617269, JString, required = false,
                                 default = nil)
  if valid_617269 != nil:
    section.add "PageSize", valid_617269
  var valid_617270 = query.getOrDefault("PageToken")
  valid_617270 = validateParameter(valid_617270, JString, required = false,
                                 default = nil)
  if valid_617270 != nil:
    section.add "PageToken", valid_617270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617271 = header.getOrDefault("X-Amz-Date")
  valid_617271 = validateParameter(valid_617271, JString, required = false,
                                 default = nil)
  if valid_617271 != nil:
    section.add "X-Amz-Date", valid_617271
  var valid_617272 = header.getOrDefault("X-Amz-Security-Token")
  valid_617272 = validateParameter(valid_617272, JString, required = false,
                                 default = nil)
  if valid_617272 != nil:
    section.add "X-Amz-Security-Token", valid_617272
  var valid_617273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617273 = validateParameter(valid_617273, JString, required = false,
                                 default = nil)
  if valid_617273 != nil:
    section.add "X-Amz-Content-Sha256", valid_617273
  var valid_617274 = header.getOrDefault("X-Amz-Algorithm")
  valid_617274 = validateParameter(valid_617274, JString, required = false,
                                 default = nil)
  if valid_617274 != nil:
    section.add "X-Amz-Algorithm", valid_617274
  var valid_617275 = header.getOrDefault("X-Amz-Signature")
  valid_617275 = validateParameter(valid_617275, JString, required = false,
                                 default = nil)
  if valid_617275 != nil:
    section.add "X-Amz-Signature", valid_617275
  var valid_617276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617276 = validateParameter(valid_617276, JString, required = false,
                                 default = nil)
  if valid_617276 != nil:
    section.add "X-Amz-SignedHeaders", valid_617276
  var valid_617277 = header.getOrDefault("X-Amz-Target")
  valid_617277 = validateParameter(valid_617277, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListLaunchPaths"))
  if valid_617277 != nil:
    section.add "X-Amz-Target", valid_617277
  var valid_617278 = header.getOrDefault("X-Amz-Credential")
  valid_617278 = validateParameter(valid_617278, JString, required = false,
                                 default = nil)
  if valid_617278 != nil:
    section.add "X-Amz-Credential", valid_617278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617280: Call_ListLaunchPaths_617266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  let valid = call_617280.validator(path, query, header, formData, body)
  let scheme = call_617280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617280.url(scheme.get, call_617280.host, call_617280.base,
                         call_617280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617280, url, valid)

proc call*(call_617281: Call_ListLaunchPaths_617266; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listLaunchPaths
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617282 = newJObject()
  var body_617283 = newJObject()
  add(query_617282, "PageSize", newJString(PageSize))
  add(query_617282, "PageToken", newJString(PageToken))
  if body != nil:
    body_617283 = body
  result = call_617281.call(nil, query_617282, nil, nil, body_617283)

var listLaunchPaths* = Call_ListLaunchPaths_617266(name: "listLaunchPaths",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths",
    validator: validate_ListLaunchPaths_617267, base: "/", url: url_ListLaunchPaths_617268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationPortfolioAccess_617284 = ref object of OpenApiRestCall_615866
proc url_ListOrganizationPortfolioAccess_617286(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOrganizationPortfolioAccess_617285(path: JsonNode;
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
  var valid_617287 = query.getOrDefault("PageSize")
  valid_617287 = validateParameter(valid_617287, JString, required = false,
                                 default = nil)
  if valid_617287 != nil:
    section.add "PageSize", valid_617287
  var valid_617288 = query.getOrDefault("PageToken")
  valid_617288 = validateParameter(valid_617288, JString, required = false,
                                 default = nil)
  if valid_617288 != nil:
    section.add "PageToken", valid_617288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617289 = header.getOrDefault("X-Amz-Date")
  valid_617289 = validateParameter(valid_617289, JString, required = false,
                                 default = nil)
  if valid_617289 != nil:
    section.add "X-Amz-Date", valid_617289
  var valid_617290 = header.getOrDefault("X-Amz-Security-Token")
  valid_617290 = validateParameter(valid_617290, JString, required = false,
                                 default = nil)
  if valid_617290 != nil:
    section.add "X-Amz-Security-Token", valid_617290
  var valid_617291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617291 = validateParameter(valid_617291, JString, required = false,
                                 default = nil)
  if valid_617291 != nil:
    section.add "X-Amz-Content-Sha256", valid_617291
  var valid_617292 = header.getOrDefault("X-Amz-Algorithm")
  valid_617292 = validateParameter(valid_617292, JString, required = false,
                                 default = nil)
  if valid_617292 != nil:
    section.add "X-Amz-Algorithm", valid_617292
  var valid_617293 = header.getOrDefault("X-Amz-Signature")
  valid_617293 = validateParameter(valid_617293, JString, required = false,
                                 default = nil)
  if valid_617293 != nil:
    section.add "X-Amz-Signature", valid_617293
  var valid_617294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617294 = validateParameter(valid_617294, JString, required = false,
                                 default = nil)
  if valid_617294 != nil:
    section.add "X-Amz-SignedHeaders", valid_617294
  var valid_617295 = header.getOrDefault("X-Amz-Target")
  valid_617295 = validateParameter(valid_617295, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"))
  if valid_617295 != nil:
    section.add "X-Amz-Target", valid_617295
  var valid_617296 = header.getOrDefault("X-Amz-Credential")
  valid_617296 = validateParameter(valid_617296, JString, required = false,
                                 default = nil)
  if valid_617296 != nil:
    section.add "X-Amz-Credential", valid_617296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617298: Call_ListOrganizationPortfolioAccess_617284;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  let valid = call_617298.validator(path, query, header, formData, body)
  let scheme = call_617298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617298.url(scheme.get, call_617298.host, call_617298.base,
                         call_617298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617298, url, valid)

proc call*(call_617299: Call_ListOrganizationPortfolioAccess_617284;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listOrganizationPortfolioAccess
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617300 = newJObject()
  var body_617301 = newJObject()
  add(query_617300, "PageSize", newJString(PageSize))
  add(query_617300, "PageToken", newJString(PageToken))
  if body != nil:
    body_617301 = body
  result = call_617299.call(nil, query_617300, nil, nil, body_617301)

var listOrganizationPortfolioAccess* = Call_ListOrganizationPortfolioAccess_617284(
    name: "listOrganizationPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess",
    validator: validate_ListOrganizationPortfolioAccess_617285, base: "/",
    url: url_ListOrganizationPortfolioAccess_617286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolioAccess_617302 = ref object of OpenApiRestCall_615866
proc url_ListPortfolioAccess_617304(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfolioAccess_617303(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the account IDs that have access to the specified portfolio.
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
  var valid_617305 = query.getOrDefault("PageSize")
  valid_617305 = validateParameter(valid_617305, JString, required = false,
                                 default = nil)
  if valid_617305 != nil:
    section.add "PageSize", valid_617305
  var valid_617306 = query.getOrDefault("PageToken")
  valid_617306 = validateParameter(valid_617306, JString, required = false,
                                 default = nil)
  if valid_617306 != nil:
    section.add "PageToken", valid_617306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617307 = header.getOrDefault("X-Amz-Date")
  valid_617307 = validateParameter(valid_617307, JString, required = false,
                                 default = nil)
  if valid_617307 != nil:
    section.add "X-Amz-Date", valid_617307
  var valid_617308 = header.getOrDefault("X-Amz-Security-Token")
  valid_617308 = validateParameter(valid_617308, JString, required = false,
                                 default = nil)
  if valid_617308 != nil:
    section.add "X-Amz-Security-Token", valid_617308
  var valid_617309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617309 = validateParameter(valid_617309, JString, required = false,
                                 default = nil)
  if valid_617309 != nil:
    section.add "X-Amz-Content-Sha256", valid_617309
  var valid_617310 = header.getOrDefault("X-Amz-Algorithm")
  valid_617310 = validateParameter(valid_617310, JString, required = false,
                                 default = nil)
  if valid_617310 != nil:
    section.add "X-Amz-Algorithm", valid_617310
  var valid_617311 = header.getOrDefault("X-Amz-Signature")
  valid_617311 = validateParameter(valid_617311, JString, required = false,
                                 default = nil)
  if valid_617311 != nil:
    section.add "X-Amz-Signature", valid_617311
  var valid_617312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617312 = validateParameter(valid_617312, JString, required = false,
                                 default = nil)
  if valid_617312 != nil:
    section.add "X-Amz-SignedHeaders", valid_617312
  var valid_617313 = header.getOrDefault("X-Amz-Target")
  valid_617313 = validateParameter(valid_617313, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolioAccess"))
  if valid_617313 != nil:
    section.add "X-Amz-Target", valid_617313
  var valid_617314 = header.getOrDefault("X-Amz-Credential")
  valid_617314 = validateParameter(valid_617314, JString, required = false,
                                 default = nil)
  if valid_617314 != nil:
    section.add "X-Amz-Credential", valid_617314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617316: Call_ListPortfolioAccess_617302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account IDs that have access to the specified portfolio.
  ## 
  let valid = call_617316.validator(path, query, header, formData, body)
  let scheme = call_617316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617316.url(scheme.get, call_617316.host, call_617316.base,
                         call_617316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617316, url, valid)

proc call*(call_617317: Call_ListPortfolioAccess_617302; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfolioAccess
  ## Lists the account IDs that have access to the specified portfolio.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617318 = newJObject()
  var body_617319 = newJObject()
  add(query_617318, "PageSize", newJString(PageSize))
  add(query_617318, "PageToken", newJString(PageToken))
  if body != nil:
    body_617319 = body
  result = call_617317.call(nil, query_617318, nil, nil, body_617319)

var listPortfolioAccess* = Call_ListPortfolioAccess_617302(
    name: "listPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess",
    validator: validate_ListPortfolioAccess_617303, base: "/",
    url: url_ListPortfolioAccess_617304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolios_617320 = ref object of OpenApiRestCall_615866
proc url_ListPortfolios_617322(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfolios_617321(path: JsonNode; query: JsonNode;
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
  var valid_617323 = query.getOrDefault("PageSize")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "PageSize", valid_617323
  var valid_617324 = query.getOrDefault("PageToken")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "PageToken", valid_617324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617325 = header.getOrDefault("X-Amz-Date")
  valid_617325 = validateParameter(valid_617325, JString, required = false,
                                 default = nil)
  if valid_617325 != nil:
    section.add "X-Amz-Date", valid_617325
  var valid_617326 = header.getOrDefault("X-Amz-Security-Token")
  valid_617326 = validateParameter(valid_617326, JString, required = false,
                                 default = nil)
  if valid_617326 != nil:
    section.add "X-Amz-Security-Token", valid_617326
  var valid_617327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617327 = validateParameter(valid_617327, JString, required = false,
                                 default = nil)
  if valid_617327 != nil:
    section.add "X-Amz-Content-Sha256", valid_617327
  var valid_617328 = header.getOrDefault("X-Amz-Algorithm")
  valid_617328 = validateParameter(valid_617328, JString, required = false,
                                 default = nil)
  if valid_617328 != nil:
    section.add "X-Amz-Algorithm", valid_617328
  var valid_617329 = header.getOrDefault("X-Amz-Signature")
  valid_617329 = validateParameter(valid_617329, JString, required = false,
                                 default = nil)
  if valid_617329 != nil:
    section.add "X-Amz-Signature", valid_617329
  var valid_617330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617330 = validateParameter(valid_617330, JString, required = false,
                                 default = nil)
  if valid_617330 != nil:
    section.add "X-Amz-SignedHeaders", valid_617330
  var valid_617331 = header.getOrDefault("X-Amz-Target")
  valid_617331 = validateParameter(valid_617331, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolios"))
  if valid_617331 != nil:
    section.add "X-Amz-Target", valid_617331
  var valid_617332 = header.getOrDefault("X-Amz-Credential")
  valid_617332 = validateParameter(valid_617332, JString, required = false,
                                 default = nil)
  if valid_617332 != nil:
    section.add "X-Amz-Credential", valid_617332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617334: Call_ListPortfolios_617320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios in the catalog.
  ## 
  let valid = call_617334.validator(path, query, header, formData, body)
  let scheme = call_617334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617334.url(scheme.get, call_617334.host, call_617334.base,
                         call_617334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617334, url, valid)

proc call*(call_617335: Call_ListPortfolios_617320; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfolios
  ## Lists all portfolios in the catalog.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617336 = newJObject()
  var body_617337 = newJObject()
  add(query_617336, "PageSize", newJString(PageSize))
  add(query_617336, "PageToken", newJString(PageToken))
  if body != nil:
    body_617337 = body
  result = call_617335.call(nil, query_617336, nil, nil, body_617337)

var listPortfolios* = Call_ListPortfolios_617320(name: "listPortfolios",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios",
    validator: validate_ListPortfolios_617321, base: "/", url: url_ListPortfolios_617322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfoliosForProduct_617338 = ref object of OpenApiRestCall_615866
proc url_ListPortfoliosForProduct_617340(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfoliosForProduct_617339(path: JsonNode; query: JsonNode;
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
  var valid_617341 = query.getOrDefault("PageSize")
  valid_617341 = validateParameter(valid_617341, JString, required = false,
                                 default = nil)
  if valid_617341 != nil:
    section.add "PageSize", valid_617341
  var valid_617342 = query.getOrDefault("PageToken")
  valid_617342 = validateParameter(valid_617342, JString, required = false,
                                 default = nil)
  if valid_617342 != nil:
    section.add "PageToken", valid_617342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617343 = header.getOrDefault("X-Amz-Date")
  valid_617343 = validateParameter(valid_617343, JString, required = false,
                                 default = nil)
  if valid_617343 != nil:
    section.add "X-Amz-Date", valid_617343
  var valid_617344 = header.getOrDefault("X-Amz-Security-Token")
  valid_617344 = validateParameter(valid_617344, JString, required = false,
                                 default = nil)
  if valid_617344 != nil:
    section.add "X-Amz-Security-Token", valid_617344
  var valid_617345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617345 = validateParameter(valid_617345, JString, required = false,
                                 default = nil)
  if valid_617345 != nil:
    section.add "X-Amz-Content-Sha256", valid_617345
  var valid_617346 = header.getOrDefault("X-Amz-Algorithm")
  valid_617346 = validateParameter(valid_617346, JString, required = false,
                                 default = nil)
  if valid_617346 != nil:
    section.add "X-Amz-Algorithm", valid_617346
  var valid_617347 = header.getOrDefault("X-Amz-Signature")
  valid_617347 = validateParameter(valid_617347, JString, required = false,
                                 default = nil)
  if valid_617347 != nil:
    section.add "X-Amz-Signature", valid_617347
  var valid_617348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617348 = validateParameter(valid_617348, JString, required = false,
                                 default = nil)
  if valid_617348 != nil:
    section.add "X-Amz-SignedHeaders", valid_617348
  var valid_617349 = header.getOrDefault("X-Amz-Target")
  valid_617349 = validateParameter(valid_617349, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfoliosForProduct"))
  if valid_617349 != nil:
    section.add "X-Amz-Target", valid_617349
  var valid_617350 = header.getOrDefault("X-Amz-Credential")
  valid_617350 = validateParameter(valid_617350, JString, required = false,
                                 default = nil)
  if valid_617350 != nil:
    section.add "X-Amz-Credential", valid_617350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617352: Call_ListPortfoliosForProduct_617338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  let valid = call_617352.validator(path, query, header, formData, body)
  let scheme = call_617352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617352.url(scheme.get, call_617352.host, call_617352.base,
                         call_617352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617352, url, valid)

proc call*(call_617353: Call_ListPortfoliosForProduct_617338; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfoliosForProduct
  ## Lists all portfolios that the specified product is associated with.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617354 = newJObject()
  var body_617355 = newJObject()
  add(query_617354, "PageSize", newJString(PageSize))
  add(query_617354, "PageToken", newJString(PageToken))
  if body != nil:
    body_617355 = body
  result = call_617353.call(nil, query_617354, nil, nil, body_617355)

var listPortfoliosForProduct* = Call_ListPortfoliosForProduct_617338(
    name: "listPortfoliosForProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct",
    validator: validate_ListPortfoliosForProduct_617339, base: "/",
    url: url_ListPortfoliosForProduct_617340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipalsForPortfolio_617356 = ref object of OpenApiRestCall_615866
proc url_ListPrincipalsForPortfolio_617358(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPrincipalsForPortfolio_617357(path: JsonNode; query: JsonNode;
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
  var valid_617359 = query.getOrDefault("PageSize")
  valid_617359 = validateParameter(valid_617359, JString, required = false,
                                 default = nil)
  if valid_617359 != nil:
    section.add "PageSize", valid_617359
  var valid_617360 = query.getOrDefault("PageToken")
  valid_617360 = validateParameter(valid_617360, JString, required = false,
                                 default = nil)
  if valid_617360 != nil:
    section.add "PageToken", valid_617360
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617361 = header.getOrDefault("X-Amz-Date")
  valid_617361 = validateParameter(valid_617361, JString, required = false,
                                 default = nil)
  if valid_617361 != nil:
    section.add "X-Amz-Date", valid_617361
  var valid_617362 = header.getOrDefault("X-Amz-Security-Token")
  valid_617362 = validateParameter(valid_617362, JString, required = false,
                                 default = nil)
  if valid_617362 != nil:
    section.add "X-Amz-Security-Token", valid_617362
  var valid_617363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617363 = validateParameter(valid_617363, JString, required = false,
                                 default = nil)
  if valid_617363 != nil:
    section.add "X-Amz-Content-Sha256", valid_617363
  var valid_617364 = header.getOrDefault("X-Amz-Algorithm")
  valid_617364 = validateParameter(valid_617364, JString, required = false,
                                 default = nil)
  if valid_617364 != nil:
    section.add "X-Amz-Algorithm", valid_617364
  var valid_617365 = header.getOrDefault("X-Amz-Signature")
  valid_617365 = validateParameter(valid_617365, JString, required = false,
                                 default = nil)
  if valid_617365 != nil:
    section.add "X-Amz-Signature", valid_617365
  var valid_617366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617366 = validateParameter(valid_617366, JString, required = false,
                                 default = nil)
  if valid_617366 != nil:
    section.add "X-Amz-SignedHeaders", valid_617366
  var valid_617367 = header.getOrDefault("X-Amz-Target")
  valid_617367 = validateParameter(valid_617367, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPrincipalsForPortfolio"))
  if valid_617367 != nil:
    section.add "X-Amz-Target", valid_617367
  var valid_617368 = header.getOrDefault("X-Amz-Credential")
  valid_617368 = validateParameter(valid_617368, JString, required = false,
                                 default = nil)
  if valid_617368 != nil:
    section.add "X-Amz-Credential", valid_617368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617370: Call_ListPrincipalsForPortfolio_617356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  let valid = call_617370.validator(path, query, header, formData, body)
  let scheme = call_617370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617370.url(scheme.get, call_617370.host, call_617370.base,
                         call_617370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617370, url, valid)

proc call*(call_617371: Call_ListPrincipalsForPortfolio_617356; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPrincipalsForPortfolio
  ## Lists all principal ARNs associated with the specified portfolio.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617372 = newJObject()
  var body_617373 = newJObject()
  add(query_617372, "PageSize", newJString(PageSize))
  add(query_617372, "PageToken", newJString(PageToken))
  if body != nil:
    body_617373 = body
  result = call_617371.call(nil, query_617372, nil, nil, body_617373)

var listPrincipalsForPortfolio* = Call_ListPrincipalsForPortfolio_617356(
    name: "listPrincipalsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio",
    validator: validate_ListPrincipalsForPortfolio_617357, base: "/",
    url: url_ListPrincipalsForPortfolio_617358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedProductPlans_617374 = ref object of OpenApiRestCall_615866
proc url_ListProvisionedProductPlans_617376(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisionedProductPlans_617375(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617377 = header.getOrDefault("X-Amz-Date")
  valid_617377 = validateParameter(valid_617377, JString, required = false,
                                 default = nil)
  if valid_617377 != nil:
    section.add "X-Amz-Date", valid_617377
  var valid_617378 = header.getOrDefault("X-Amz-Security-Token")
  valid_617378 = validateParameter(valid_617378, JString, required = false,
                                 default = nil)
  if valid_617378 != nil:
    section.add "X-Amz-Security-Token", valid_617378
  var valid_617379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617379 = validateParameter(valid_617379, JString, required = false,
                                 default = nil)
  if valid_617379 != nil:
    section.add "X-Amz-Content-Sha256", valid_617379
  var valid_617380 = header.getOrDefault("X-Amz-Algorithm")
  valid_617380 = validateParameter(valid_617380, JString, required = false,
                                 default = nil)
  if valid_617380 != nil:
    section.add "X-Amz-Algorithm", valid_617380
  var valid_617381 = header.getOrDefault("X-Amz-Signature")
  valid_617381 = validateParameter(valid_617381, JString, required = false,
                                 default = nil)
  if valid_617381 != nil:
    section.add "X-Amz-Signature", valid_617381
  var valid_617382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617382 = validateParameter(valid_617382, JString, required = false,
                                 default = nil)
  if valid_617382 != nil:
    section.add "X-Amz-SignedHeaders", valid_617382
  var valid_617383 = header.getOrDefault("X-Amz-Target")
  valid_617383 = validateParameter(valid_617383, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisionedProductPlans"))
  if valid_617383 != nil:
    section.add "X-Amz-Target", valid_617383
  var valid_617384 = header.getOrDefault("X-Amz-Credential")
  valid_617384 = validateParameter(valid_617384, JString, required = false,
                                 default = nil)
  if valid_617384 != nil:
    section.add "X-Amz-Credential", valid_617384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617386: Call_ListProvisionedProductPlans_617374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ## 
  let valid = call_617386.validator(path, query, header, formData, body)
  let scheme = call_617386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617386.url(scheme.get, call_617386.host, call_617386.base,
                         call_617386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617386, url, valid)

proc call*(call_617387: Call_ListProvisionedProductPlans_617374; body: JsonNode): Recallable =
  ## listProvisionedProductPlans
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ##   body: JObject (required)
  var body_617388 = newJObject()
  if body != nil:
    body_617388 = body
  result = call_617387.call(nil, nil, nil, nil, body_617388)

var listProvisionedProductPlans* = Call_ListProvisionedProductPlans_617374(
    name: "listProvisionedProductPlans", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans",
    validator: validate_ListProvisionedProductPlans_617375, base: "/",
    url: url_ListProvisionedProductPlans_617376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifacts_617389 = ref object of OpenApiRestCall_615866
proc url_ListProvisioningArtifacts_617391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisioningArtifacts_617390(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617392 = header.getOrDefault("X-Amz-Date")
  valid_617392 = validateParameter(valid_617392, JString, required = false,
                                 default = nil)
  if valid_617392 != nil:
    section.add "X-Amz-Date", valid_617392
  var valid_617393 = header.getOrDefault("X-Amz-Security-Token")
  valid_617393 = validateParameter(valid_617393, JString, required = false,
                                 default = nil)
  if valid_617393 != nil:
    section.add "X-Amz-Security-Token", valid_617393
  var valid_617394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617394 = validateParameter(valid_617394, JString, required = false,
                                 default = nil)
  if valid_617394 != nil:
    section.add "X-Amz-Content-Sha256", valid_617394
  var valid_617395 = header.getOrDefault("X-Amz-Algorithm")
  valid_617395 = validateParameter(valid_617395, JString, required = false,
                                 default = nil)
  if valid_617395 != nil:
    section.add "X-Amz-Algorithm", valid_617395
  var valid_617396 = header.getOrDefault("X-Amz-Signature")
  valid_617396 = validateParameter(valid_617396, JString, required = false,
                                 default = nil)
  if valid_617396 != nil:
    section.add "X-Amz-Signature", valid_617396
  var valid_617397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617397 = validateParameter(valid_617397, JString, required = false,
                                 default = nil)
  if valid_617397 != nil:
    section.add "X-Amz-SignedHeaders", valid_617397
  var valid_617398 = header.getOrDefault("X-Amz-Target")
  valid_617398 = validateParameter(valid_617398, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifacts"))
  if valid_617398 != nil:
    section.add "X-Amz-Target", valid_617398
  var valid_617399 = header.getOrDefault("X-Amz-Credential")
  valid_617399 = validateParameter(valid_617399, JString, required = false,
                                 default = nil)
  if valid_617399 != nil:
    section.add "X-Amz-Credential", valid_617399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617401: Call_ListProvisioningArtifacts_617389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ## 
  let valid = call_617401.validator(path, query, header, formData, body)
  let scheme = call_617401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617401.url(scheme.get, call_617401.host, call_617401.base,
                         call_617401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617401, url, valid)

proc call*(call_617402: Call_ListProvisioningArtifacts_617389; body: JsonNode): Recallable =
  ## listProvisioningArtifacts
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ##   body: JObject (required)
  var body_617403 = newJObject()
  if body != nil:
    body_617403 = body
  result = call_617402.call(nil, nil, nil, nil, body_617403)

var listProvisioningArtifacts* = Call_ListProvisioningArtifacts_617389(
    name: "listProvisioningArtifacts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts",
    validator: validate_ListProvisioningArtifacts_617390, base: "/",
    url: url_ListProvisioningArtifacts_617391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifactsForServiceAction_617404 = ref object of OpenApiRestCall_615866
proc url_ListProvisioningArtifactsForServiceAction_617406(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisioningArtifactsForServiceAction_617405(path: JsonNode;
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
  var valid_617407 = query.getOrDefault("PageSize")
  valid_617407 = validateParameter(valid_617407, JString, required = false,
                                 default = nil)
  if valid_617407 != nil:
    section.add "PageSize", valid_617407
  var valid_617408 = query.getOrDefault("PageToken")
  valid_617408 = validateParameter(valid_617408, JString, required = false,
                                 default = nil)
  if valid_617408 != nil:
    section.add "PageToken", valid_617408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617409 = header.getOrDefault("X-Amz-Date")
  valid_617409 = validateParameter(valid_617409, JString, required = false,
                                 default = nil)
  if valid_617409 != nil:
    section.add "X-Amz-Date", valid_617409
  var valid_617410 = header.getOrDefault("X-Amz-Security-Token")
  valid_617410 = validateParameter(valid_617410, JString, required = false,
                                 default = nil)
  if valid_617410 != nil:
    section.add "X-Amz-Security-Token", valid_617410
  var valid_617411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617411 = validateParameter(valid_617411, JString, required = false,
                                 default = nil)
  if valid_617411 != nil:
    section.add "X-Amz-Content-Sha256", valid_617411
  var valid_617412 = header.getOrDefault("X-Amz-Algorithm")
  valid_617412 = validateParameter(valid_617412, JString, required = false,
                                 default = nil)
  if valid_617412 != nil:
    section.add "X-Amz-Algorithm", valid_617412
  var valid_617413 = header.getOrDefault("X-Amz-Signature")
  valid_617413 = validateParameter(valid_617413, JString, required = false,
                                 default = nil)
  if valid_617413 != nil:
    section.add "X-Amz-Signature", valid_617413
  var valid_617414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617414 = validateParameter(valid_617414, JString, required = false,
                                 default = nil)
  if valid_617414 != nil:
    section.add "X-Amz-SignedHeaders", valid_617414
  var valid_617415 = header.getOrDefault("X-Amz-Target")
  valid_617415 = validateParameter(valid_617415, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"))
  if valid_617415 != nil:
    section.add "X-Amz-Target", valid_617415
  var valid_617416 = header.getOrDefault("X-Amz-Credential")
  valid_617416 = validateParameter(valid_617416, JString, required = false,
                                 default = nil)
  if valid_617416 != nil:
    section.add "X-Amz-Credential", valid_617416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617418: Call_ListProvisioningArtifactsForServiceAction_617404;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  let valid = call_617418.validator(path, query, header, formData, body)
  let scheme = call_617418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617418.url(scheme.get, call_617418.host, call_617418.base,
                         call_617418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617418, url, valid)

proc call*(call_617419: Call_ListProvisioningArtifactsForServiceAction_617404;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listProvisioningArtifactsForServiceAction
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617420 = newJObject()
  var body_617421 = newJObject()
  add(query_617420, "PageSize", newJString(PageSize))
  add(query_617420, "PageToken", newJString(PageToken))
  if body != nil:
    body_617421 = body
  result = call_617419.call(nil, query_617420, nil, nil, body_617421)

var listProvisioningArtifactsForServiceAction* = Call_ListProvisioningArtifactsForServiceAction_617404(
    name: "listProvisioningArtifactsForServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction",
    validator: validate_ListProvisioningArtifactsForServiceAction_617405,
    base: "/", url: url_ListProvisioningArtifactsForServiceAction_617406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecordHistory_617422 = ref object of OpenApiRestCall_615866
proc url_ListRecordHistory_617424(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRecordHistory_617423(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617425 = header.getOrDefault("X-Amz-Date")
  valid_617425 = validateParameter(valid_617425, JString, required = false,
                                 default = nil)
  if valid_617425 != nil:
    section.add "X-Amz-Date", valid_617425
  var valid_617426 = header.getOrDefault("X-Amz-Security-Token")
  valid_617426 = validateParameter(valid_617426, JString, required = false,
                                 default = nil)
  if valid_617426 != nil:
    section.add "X-Amz-Security-Token", valid_617426
  var valid_617427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617427 = validateParameter(valid_617427, JString, required = false,
                                 default = nil)
  if valid_617427 != nil:
    section.add "X-Amz-Content-Sha256", valid_617427
  var valid_617428 = header.getOrDefault("X-Amz-Algorithm")
  valid_617428 = validateParameter(valid_617428, JString, required = false,
                                 default = nil)
  if valid_617428 != nil:
    section.add "X-Amz-Algorithm", valid_617428
  var valid_617429 = header.getOrDefault("X-Amz-Signature")
  valid_617429 = validateParameter(valid_617429, JString, required = false,
                                 default = nil)
  if valid_617429 != nil:
    section.add "X-Amz-Signature", valid_617429
  var valid_617430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617430 = validateParameter(valid_617430, JString, required = false,
                                 default = nil)
  if valid_617430 != nil:
    section.add "X-Amz-SignedHeaders", valid_617430
  var valid_617431 = header.getOrDefault("X-Amz-Target")
  valid_617431 = validateParameter(valid_617431, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListRecordHistory"))
  if valid_617431 != nil:
    section.add "X-Amz-Target", valid_617431
  var valid_617432 = header.getOrDefault("X-Amz-Credential")
  valid_617432 = validateParameter(valid_617432, JString, required = false,
                                 default = nil)
  if valid_617432 != nil:
    section.add "X-Amz-Credential", valid_617432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617434: Call_ListRecordHistory_617422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified requests or all performed requests.
  ## 
  let valid = call_617434.validator(path, query, header, formData, body)
  let scheme = call_617434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617434.url(scheme.get, call_617434.host, call_617434.base,
                         call_617434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617434, url, valid)

proc call*(call_617435: Call_ListRecordHistory_617422; body: JsonNode): Recallable =
  ## listRecordHistory
  ## Lists the specified requests or all performed requests.
  ##   body: JObject (required)
  var body_617436 = newJObject()
  if body != nil:
    body_617436 = body
  result = call_617435.call(nil, nil, nil, nil, body_617436)

var listRecordHistory* = Call_ListRecordHistory_617422(name: "listRecordHistory",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory",
    validator: validate_ListRecordHistory_617423, base: "/",
    url: url_ListRecordHistory_617424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForTagOption_617437 = ref object of OpenApiRestCall_615866
proc url_ListResourcesForTagOption_617439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourcesForTagOption_617438(path: JsonNode; query: JsonNode;
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
  var valid_617440 = query.getOrDefault("PageSize")
  valid_617440 = validateParameter(valid_617440, JString, required = false,
                                 default = nil)
  if valid_617440 != nil:
    section.add "PageSize", valid_617440
  var valid_617441 = query.getOrDefault("PageToken")
  valid_617441 = validateParameter(valid_617441, JString, required = false,
                                 default = nil)
  if valid_617441 != nil:
    section.add "PageToken", valid_617441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617442 = header.getOrDefault("X-Amz-Date")
  valid_617442 = validateParameter(valid_617442, JString, required = false,
                                 default = nil)
  if valid_617442 != nil:
    section.add "X-Amz-Date", valid_617442
  var valid_617443 = header.getOrDefault("X-Amz-Security-Token")
  valid_617443 = validateParameter(valid_617443, JString, required = false,
                                 default = nil)
  if valid_617443 != nil:
    section.add "X-Amz-Security-Token", valid_617443
  var valid_617444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617444 = validateParameter(valid_617444, JString, required = false,
                                 default = nil)
  if valid_617444 != nil:
    section.add "X-Amz-Content-Sha256", valid_617444
  var valid_617445 = header.getOrDefault("X-Amz-Algorithm")
  valid_617445 = validateParameter(valid_617445, JString, required = false,
                                 default = nil)
  if valid_617445 != nil:
    section.add "X-Amz-Algorithm", valid_617445
  var valid_617446 = header.getOrDefault("X-Amz-Signature")
  valid_617446 = validateParameter(valid_617446, JString, required = false,
                                 default = nil)
  if valid_617446 != nil:
    section.add "X-Amz-Signature", valid_617446
  var valid_617447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617447 = validateParameter(valid_617447, JString, required = false,
                                 default = nil)
  if valid_617447 != nil:
    section.add "X-Amz-SignedHeaders", valid_617447
  var valid_617448 = header.getOrDefault("X-Amz-Target")
  valid_617448 = validateParameter(valid_617448, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListResourcesForTagOption"))
  if valid_617448 != nil:
    section.add "X-Amz-Target", valid_617448
  var valid_617449 = header.getOrDefault("X-Amz-Credential")
  valid_617449 = validateParameter(valid_617449, JString, required = false,
                                 default = nil)
  if valid_617449 != nil:
    section.add "X-Amz-Credential", valid_617449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617451: Call_ListResourcesForTagOption_617437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources associated with the specified TagOption.
  ## 
  let valid = call_617451.validator(path, query, header, formData, body)
  let scheme = call_617451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617451.url(scheme.get, call_617451.host, call_617451.base,
                         call_617451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617451, url, valid)

proc call*(call_617452: Call_ListResourcesForTagOption_617437; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listResourcesForTagOption
  ## Lists the resources associated with the specified TagOption.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617453 = newJObject()
  var body_617454 = newJObject()
  add(query_617453, "PageSize", newJString(PageSize))
  add(query_617453, "PageToken", newJString(PageToken))
  if body != nil:
    body_617454 = body
  result = call_617452.call(nil, query_617453, nil, nil, body_617454)

var listResourcesForTagOption* = Call_ListResourcesForTagOption_617437(
    name: "listResourcesForTagOption", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption",
    validator: validate_ListResourcesForTagOption_617438, base: "/",
    url: url_ListResourcesForTagOption_617439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActions_617455 = ref object of OpenApiRestCall_615866
proc url_ListServiceActions_617457(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceActions_617456(path: JsonNode; query: JsonNode;
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
  var valid_617458 = query.getOrDefault("PageSize")
  valid_617458 = validateParameter(valid_617458, JString, required = false,
                                 default = nil)
  if valid_617458 != nil:
    section.add "PageSize", valid_617458
  var valid_617459 = query.getOrDefault("PageToken")
  valid_617459 = validateParameter(valid_617459, JString, required = false,
                                 default = nil)
  if valid_617459 != nil:
    section.add "PageToken", valid_617459
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617460 = header.getOrDefault("X-Amz-Date")
  valid_617460 = validateParameter(valid_617460, JString, required = false,
                                 default = nil)
  if valid_617460 != nil:
    section.add "X-Amz-Date", valid_617460
  var valid_617461 = header.getOrDefault("X-Amz-Security-Token")
  valid_617461 = validateParameter(valid_617461, JString, required = false,
                                 default = nil)
  if valid_617461 != nil:
    section.add "X-Amz-Security-Token", valid_617461
  var valid_617462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617462 = validateParameter(valid_617462, JString, required = false,
                                 default = nil)
  if valid_617462 != nil:
    section.add "X-Amz-Content-Sha256", valid_617462
  var valid_617463 = header.getOrDefault("X-Amz-Algorithm")
  valid_617463 = validateParameter(valid_617463, JString, required = false,
                                 default = nil)
  if valid_617463 != nil:
    section.add "X-Amz-Algorithm", valid_617463
  var valid_617464 = header.getOrDefault("X-Amz-Signature")
  valid_617464 = validateParameter(valid_617464, JString, required = false,
                                 default = nil)
  if valid_617464 != nil:
    section.add "X-Amz-Signature", valid_617464
  var valid_617465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617465 = validateParameter(valid_617465, JString, required = false,
                                 default = nil)
  if valid_617465 != nil:
    section.add "X-Amz-SignedHeaders", valid_617465
  var valid_617466 = header.getOrDefault("X-Amz-Target")
  valid_617466 = validateParameter(valid_617466, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActions"))
  if valid_617466 != nil:
    section.add "X-Amz-Target", valid_617466
  var valid_617467 = header.getOrDefault("X-Amz-Credential")
  valid_617467 = validateParameter(valid_617467, JString, required = false,
                                 default = nil)
  if valid_617467 != nil:
    section.add "X-Amz-Credential", valid_617467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617469: Call_ListServiceActions_617455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all self-service actions.
  ## 
  let valid = call_617469.validator(path, query, header, formData, body)
  let scheme = call_617469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617469.url(scheme.get, call_617469.host, call_617469.base,
                         call_617469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617469, url, valid)

proc call*(call_617470: Call_ListServiceActions_617455; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActions
  ## Lists all self-service actions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617471 = newJObject()
  var body_617472 = newJObject()
  add(query_617471, "PageSize", newJString(PageSize))
  add(query_617471, "PageToken", newJString(PageToken))
  if body != nil:
    body_617472 = body
  result = call_617470.call(nil, query_617471, nil, nil, body_617472)

var listServiceActions* = Call_ListServiceActions_617455(
    name: "listServiceActions", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions",
    validator: validate_ListServiceActions_617456, base: "/",
    url: url_ListServiceActions_617457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActionsForProvisioningArtifact_617473 = ref object of OpenApiRestCall_615866
proc url_ListServiceActionsForProvisioningArtifact_617475(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceActionsForProvisioningArtifact_617474(path: JsonNode;
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
  var valid_617476 = query.getOrDefault("PageSize")
  valid_617476 = validateParameter(valid_617476, JString, required = false,
                                 default = nil)
  if valid_617476 != nil:
    section.add "PageSize", valid_617476
  var valid_617477 = query.getOrDefault("PageToken")
  valid_617477 = validateParameter(valid_617477, JString, required = false,
                                 default = nil)
  if valid_617477 != nil:
    section.add "PageToken", valid_617477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617478 = header.getOrDefault("X-Amz-Date")
  valid_617478 = validateParameter(valid_617478, JString, required = false,
                                 default = nil)
  if valid_617478 != nil:
    section.add "X-Amz-Date", valid_617478
  var valid_617479 = header.getOrDefault("X-Amz-Security-Token")
  valid_617479 = validateParameter(valid_617479, JString, required = false,
                                 default = nil)
  if valid_617479 != nil:
    section.add "X-Amz-Security-Token", valid_617479
  var valid_617480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617480 = validateParameter(valid_617480, JString, required = false,
                                 default = nil)
  if valid_617480 != nil:
    section.add "X-Amz-Content-Sha256", valid_617480
  var valid_617481 = header.getOrDefault("X-Amz-Algorithm")
  valid_617481 = validateParameter(valid_617481, JString, required = false,
                                 default = nil)
  if valid_617481 != nil:
    section.add "X-Amz-Algorithm", valid_617481
  var valid_617482 = header.getOrDefault("X-Amz-Signature")
  valid_617482 = validateParameter(valid_617482, JString, required = false,
                                 default = nil)
  if valid_617482 != nil:
    section.add "X-Amz-Signature", valid_617482
  var valid_617483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "X-Amz-SignedHeaders", valid_617483
  var valid_617484 = header.getOrDefault("X-Amz-Target")
  valid_617484 = validateParameter(valid_617484, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"))
  if valid_617484 != nil:
    section.add "X-Amz-Target", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-Credential")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-Credential", valid_617485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617487: Call_ListServiceActionsForProvisioningArtifact_617473;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  let valid = call_617487.validator(path, query, header, formData, body)
  let scheme = call_617487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617487.url(scheme.get, call_617487.host, call_617487.base,
                         call_617487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617487, url, valid)

proc call*(call_617488: Call_ListServiceActionsForProvisioningArtifact_617473;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActionsForProvisioningArtifact
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617489 = newJObject()
  var body_617490 = newJObject()
  add(query_617489, "PageSize", newJString(PageSize))
  add(query_617489, "PageToken", newJString(PageToken))
  if body != nil:
    body_617490 = body
  result = call_617488.call(nil, query_617489, nil, nil, body_617490)

var listServiceActionsForProvisioningArtifact* = Call_ListServiceActionsForProvisioningArtifact_617473(
    name: "listServiceActionsForProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact",
    validator: validate_ListServiceActionsForProvisioningArtifact_617474,
    base: "/", url: url_ListServiceActionsForProvisioningArtifact_617475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStackInstancesForProvisionedProduct_617491 = ref object of OpenApiRestCall_615866
proc url_ListStackInstancesForProvisionedProduct_617493(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStackInstancesForProvisionedProduct_617492(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617494 = header.getOrDefault("X-Amz-Date")
  valid_617494 = validateParameter(valid_617494, JString, required = false,
                                 default = nil)
  if valid_617494 != nil:
    section.add "X-Amz-Date", valid_617494
  var valid_617495 = header.getOrDefault("X-Amz-Security-Token")
  valid_617495 = validateParameter(valid_617495, JString, required = false,
                                 default = nil)
  if valid_617495 != nil:
    section.add "X-Amz-Security-Token", valid_617495
  var valid_617496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617496 = validateParameter(valid_617496, JString, required = false,
                                 default = nil)
  if valid_617496 != nil:
    section.add "X-Amz-Content-Sha256", valid_617496
  var valid_617497 = header.getOrDefault("X-Amz-Algorithm")
  valid_617497 = validateParameter(valid_617497, JString, required = false,
                                 default = nil)
  if valid_617497 != nil:
    section.add "X-Amz-Algorithm", valid_617497
  var valid_617498 = header.getOrDefault("X-Amz-Signature")
  valid_617498 = validateParameter(valid_617498, JString, required = false,
                                 default = nil)
  if valid_617498 != nil:
    section.add "X-Amz-Signature", valid_617498
  var valid_617499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "X-Amz-SignedHeaders", valid_617499
  var valid_617500 = header.getOrDefault("X-Amz-Target")
  valid_617500 = validateParameter(valid_617500, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"))
  if valid_617500 != nil:
    section.add "X-Amz-Target", valid_617500
  var valid_617501 = header.getOrDefault("X-Amz-Credential")
  valid_617501 = validateParameter(valid_617501, JString, required = false,
                                 default = nil)
  if valid_617501 != nil:
    section.add "X-Amz-Credential", valid_617501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617503: Call_ListStackInstancesForProvisionedProduct_617491;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ## 
  let valid = call_617503.validator(path, query, header, formData, body)
  let scheme = call_617503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617503.url(scheme.get, call_617503.host, call_617503.base,
                         call_617503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617503, url, valid)

proc call*(call_617504: Call_ListStackInstancesForProvisionedProduct_617491;
          body: JsonNode): Recallable =
  ## listStackInstancesForProvisionedProduct
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ##   body: JObject (required)
  var body_617505 = newJObject()
  if body != nil:
    body_617505 = body
  result = call_617504.call(nil, nil, nil, nil, body_617505)

var listStackInstancesForProvisionedProduct* = Call_ListStackInstancesForProvisionedProduct_617491(
    name: "listStackInstancesForProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct",
    validator: validate_ListStackInstancesForProvisionedProduct_617492, base: "/",
    url: url_ListStackInstancesForProvisionedProduct_617493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagOptions_617506 = ref object of OpenApiRestCall_615866
proc url_ListTagOptions_617508(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagOptions_617507(path: JsonNode; query: JsonNode;
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
  var valid_617509 = query.getOrDefault("PageSize")
  valid_617509 = validateParameter(valid_617509, JString, required = false,
                                 default = nil)
  if valid_617509 != nil:
    section.add "PageSize", valid_617509
  var valid_617510 = query.getOrDefault("PageToken")
  valid_617510 = validateParameter(valid_617510, JString, required = false,
                                 default = nil)
  if valid_617510 != nil:
    section.add "PageToken", valid_617510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617511 = header.getOrDefault("X-Amz-Date")
  valid_617511 = validateParameter(valid_617511, JString, required = false,
                                 default = nil)
  if valid_617511 != nil:
    section.add "X-Amz-Date", valid_617511
  var valid_617512 = header.getOrDefault("X-Amz-Security-Token")
  valid_617512 = validateParameter(valid_617512, JString, required = false,
                                 default = nil)
  if valid_617512 != nil:
    section.add "X-Amz-Security-Token", valid_617512
  var valid_617513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617513 = validateParameter(valid_617513, JString, required = false,
                                 default = nil)
  if valid_617513 != nil:
    section.add "X-Amz-Content-Sha256", valid_617513
  var valid_617514 = header.getOrDefault("X-Amz-Algorithm")
  valid_617514 = validateParameter(valid_617514, JString, required = false,
                                 default = nil)
  if valid_617514 != nil:
    section.add "X-Amz-Algorithm", valid_617514
  var valid_617515 = header.getOrDefault("X-Amz-Signature")
  valid_617515 = validateParameter(valid_617515, JString, required = false,
                                 default = nil)
  if valid_617515 != nil:
    section.add "X-Amz-Signature", valid_617515
  var valid_617516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617516 = validateParameter(valid_617516, JString, required = false,
                                 default = nil)
  if valid_617516 != nil:
    section.add "X-Amz-SignedHeaders", valid_617516
  var valid_617517 = header.getOrDefault("X-Amz-Target")
  valid_617517 = validateParameter(valid_617517, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListTagOptions"))
  if valid_617517 != nil:
    section.add "X-Amz-Target", valid_617517
  var valid_617518 = header.getOrDefault("X-Amz-Credential")
  valid_617518 = validateParameter(valid_617518, JString, required = false,
                                 default = nil)
  if valid_617518 != nil:
    section.add "X-Amz-Credential", valid_617518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617520: Call_ListTagOptions_617506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  let valid = call_617520.validator(path, query, header, formData, body)
  let scheme = call_617520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617520.url(scheme.get, call_617520.host, call_617520.base,
                         call_617520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617520, url, valid)

proc call*(call_617521: Call_ListTagOptions_617506; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listTagOptions
  ## Lists the specified TagOptions or all TagOptions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617522 = newJObject()
  var body_617523 = newJObject()
  add(query_617522, "PageSize", newJString(PageSize))
  add(query_617522, "PageToken", newJString(PageToken))
  if body != nil:
    body_617523 = body
  result = call_617521.call(nil, query_617522, nil, nil, body_617523)

var listTagOptions* = Call_ListTagOptions_617506(name: "listTagOptions",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions",
    validator: validate_ListTagOptions_617507, base: "/", url: url_ListTagOptions_617508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ProvisionProduct_617524 = ref object of OpenApiRestCall_615866
proc url_ProvisionProduct_617526(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ProvisionProduct_617525(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617527 = header.getOrDefault("X-Amz-Date")
  valid_617527 = validateParameter(valid_617527, JString, required = false,
                                 default = nil)
  if valid_617527 != nil:
    section.add "X-Amz-Date", valid_617527
  var valid_617528 = header.getOrDefault("X-Amz-Security-Token")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Security-Token", valid_617528
  var valid_617529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617529 = validateParameter(valid_617529, JString, required = false,
                                 default = nil)
  if valid_617529 != nil:
    section.add "X-Amz-Content-Sha256", valid_617529
  var valid_617530 = header.getOrDefault("X-Amz-Algorithm")
  valid_617530 = validateParameter(valid_617530, JString, required = false,
                                 default = nil)
  if valid_617530 != nil:
    section.add "X-Amz-Algorithm", valid_617530
  var valid_617531 = header.getOrDefault("X-Amz-Signature")
  valid_617531 = validateParameter(valid_617531, JString, required = false,
                                 default = nil)
  if valid_617531 != nil:
    section.add "X-Amz-Signature", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-SignedHeaders", valid_617532
  var valid_617533 = header.getOrDefault("X-Amz-Target")
  valid_617533 = validateParameter(valid_617533, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ProvisionProduct"))
  if valid_617533 != nil:
    section.add "X-Amz-Target", valid_617533
  var valid_617534 = header.getOrDefault("X-Amz-Credential")
  valid_617534 = validateParameter(valid_617534, JString, required = false,
                                 default = nil)
  if valid_617534 != nil:
    section.add "X-Amz-Credential", valid_617534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617536: Call_ProvisionProduct_617524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ## 
  let valid = call_617536.validator(path, query, header, formData, body)
  let scheme = call_617536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617536.url(scheme.get, call_617536.host, call_617536.base,
                         call_617536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617536, url, valid)

proc call*(call_617537: Call_ProvisionProduct_617524; body: JsonNode): Recallable =
  ## provisionProduct
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ##   body: JObject (required)
  var body_617538 = newJObject()
  if body != nil:
    body_617538 = body
  result = call_617537.call(nil, nil, nil, nil, body_617538)

var provisionProduct* = Call_ProvisionProduct_617524(name: "provisionProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct",
    validator: validate_ProvisionProduct_617525, base: "/",
    url: url_ProvisionProduct_617526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectPortfolioShare_617539 = ref object of OpenApiRestCall_615866
proc url_RejectPortfolioShare_617541(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectPortfolioShare_617540(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617542 = header.getOrDefault("X-Amz-Date")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-Date", valid_617542
  var valid_617543 = header.getOrDefault("X-Amz-Security-Token")
  valid_617543 = validateParameter(valid_617543, JString, required = false,
                                 default = nil)
  if valid_617543 != nil:
    section.add "X-Amz-Security-Token", valid_617543
  var valid_617544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617544 = validateParameter(valid_617544, JString, required = false,
                                 default = nil)
  if valid_617544 != nil:
    section.add "X-Amz-Content-Sha256", valid_617544
  var valid_617545 = header.getOrDefault("X-Amz-Algorithm")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "X-Amz-Algorithm", valid_617545
  var valid_617546 = header.getOrDefault("X-Amz-Signature")
  valid_617546 = validateParameter(valid_617546, JString, required = false,
                                 default = nil)
  if valid_617546 != nil:
    section.add "X-Amz-Signature", valid_617546
  var valid_617547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617547 = validateParameter(valid_617547, JString, required = false,
                                 default = nil)
  if valid_617547 != nil:
    section.add "X-Amz-SignedHeaders", valid_617547
  var valid_617548 = header.getOrDefault("X-Amz-Target")
  valid_617548 = validateParameter(valid_617548, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.RejectPortfolioShare"))
  if valid_617548 != nil:
    section.add "X-Amz-Target", valid_617548
  var valid_617549 = header.getOrDefault("X-Amz-Credential")
  valid_617549 = validateParameter(valid_617549, JString, required = false,
                                 default = nil)
  if valid_617549 != nil:
    section.add "X-Amz-Credential", valid_617549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617551: Call_RejectPortfolioShare_617539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an offer to share the specified portfolio.
  ## 
  let valid = call_617551.validator(path, query, header, formData, body)
  let scheme = call_617551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617551.url(scheme.get, call_617551.host, call_617551.base,
                         call_617551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617551, url, valid)

proc call*(call_617552: Call_RejectPortfolioShare_617539; body: JsonNode): Recallable =
  ## rejectPortfolioShare
  ## Rejects an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_617553 = newJObject()
  if body != nil:
    body_617553 = body
  result = call_617552.call(nil, nil, nil, nil, body_617553)

var rejectPortfolioShare* = Call_RejectPortfolioShare_617539(
    name: "rejectPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare",
    validator: validate_RejectPortfolioShare_617540, base: "/",
    url: url_RejectPortfolioShare_617541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScanProvisionedProducts_617554 = ref object of OpenApiRestCall_615866
proc url_ScanProvisionedProducts_617556(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ScanProvisionedProducts_617555(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617557 = header.getOrDefault("X-Amz-Date")
  valid_617557 = validateParameter(valid_617557, JString, required = false,
                                 default = nil)
  if valid_617557 != nil:
    section.add "X-Amz-Date", valid_617557
  var valid_617558 = header.getOrDefault("X-Amz-Security-Token")
  valid_617558 = validateParameter(valid_617558, JString, required = false,
                                 default = nil)
  if valid_617558 != nil:
    section.add "X-Amz-Security-Token", valid_617558
  var valid_617559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617559 = validateParameter(valid_617559, JString, required = false,
                                 default = nil)
  if valid_617559 != nil:
    section.add "X-Amz-Content-Sha256", valid_617559
  var valid_617560 = header.getOrDefault("X-Amz-Algorithm")
  valid_617560 = validateParameter(valid_617560, JString, required = false,
                                 default = nil)
  if valid_617560 != nil:
    section.add "X-Amz-Algorithm", valid_617560
  var valid_617561 = header.getOrDefault("X-Amz-Signature")
  valid_617561 = validateParameter(valid_617561, JString, required = false,
                                 default = nil)
  if valid_617561 != nil:
    section.add "X-Amz-Signature", valid_617561
  var valid_617562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617562 = validateParameter(valid_617562, JString, required = false,
                                 default = nil)
  if valid_617562 != nil:
    section.add "X-Amz-SignedHeaders", valid_617562
  var valid_617563 = header.getOrDefault("X-Amz-Target")
  valid_617563 = validateParameter(valid_617563, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ScanProvisionedProducts"))
  if valid_617563 != nil:
    section.add "X-Amz-Target", valid_617563
  var valid_617564 = header.getOrDefault("X-Amz-Credential")
  valid_617564 = validateParameter(valid_617564, JString, required = false,
                                 default = nil)
  if valid_617564 != nil:
    section.add "X-Amz-Credential", valid_617564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617566: Call_ScanProvisionedProducts_617554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ## 
  let valid = call_617566.validator(path, query, header, formData, body)
  let scheme = call_617566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617566.url(scheme.get, call_617566.host, call_617566.base,
                         call_617566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617566, url, valid)

proc call*(call_617567: Call_ScanProvisionedProducts_617554; body: JsonNode): Recallable =
  ## scanProvisionedProducts
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ##   body: JObject (required)
  var body_617568 = newJObject()
  if body != nil:
    body_617568 = body
  result = call_617567.call(nil, nil, nil, nil, body_617568)

var scanProvisionedProducts* = Call_ScanProvisionedProducts_617554(
    name: "scanProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts",
    validator: validate_ScanProvisionedProducts_617555, base: "/",
    url: url_ScanProvisionedProducts_617556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProducts_617569 = ref object of OpenApiRestCall_615866
proc url_SearchProducts_617571(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProducts_617570(path: JsonNode; query: JsonNode;
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
  var valid_617572 = query.getOrDefault("PageSize")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "PageSize", valid_617572
  var valid_617573 = query.getOrDefault("PageToken")
  valid_617573 = validateParameter(valid_617573, JString, required = false,
                                 default = nil)
  if valid_617573 != nil:
    section.add "PageToken", valid_617573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617574 = header.getOrDefault("X-Amz-Date")
  valid_617574 = validateParameter(valid_617574, JString, required = false,
                                 default = nil)
  if valid_617574 != nil:
    section.add "X-Amz-Date", valid_617574
  var valid_617575 = header.getOrDefault("X-Amz-Security-Token")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-Security-Token", valid_617575
  var valid_617576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617576 = validateParameter(valid_617576, JString, required = false,
                                 default = nil)
  if valid_617576 != nil:
    section.add "X-Amz-Content-Sha256", valid_617576
  var valid_617577 = header.getOrDefault("X-Amz-Algorithm")
  valid_617577 = validateParameter(valid_617577, JString, required = false,
                                 default = nil)
  if valid_617577 != nil:
    section.add "X-Amz-Algorithm", valid_617577
  var valid_617578 = header.getOrDefault("X-Amz-Signature")
  valid_617578 = validateParameter(valid_617578, JString, required = false,
                                 default = nil)
  if valid_617578 != nil:
    section.add "X-Amz-Signature", valid_617578
  var valid_617579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617579 = validateParameter(valid_617579, JString, required = false,
                                 default = nil)
  if valid_617579 != nil:
    section.add "X-Amz-SignedHeaders", valid_617579
  var valid_617580 = header.getOrDefault("X-Amz-Target")
  valid_617580 = validateParameter(valid_617580, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProducts"))
  if valid_617580 != nil:
    section.add "X-Amz-Target", valid_617580
  var valid_617581 = header.getOrDefault("X-Amz-Credential")
  valid_617581 = validateParameter(valid_617581, JString, required = false,
                                 default = nil)
  if valid_617581 != nil:
    section.add "X-Amz-Credential", valid_617581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617583: Call_SearchProducts_617569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products to which the caller has access.
  ## 
  let valid = call_617583.validator(path, query, header, formData, body)
  let scheme = call_617583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617583.url(scheme.get, call_617583.host, call_617583.base,
                         call_617583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617583, url, valid)

proc call*(call_617584: Call_SearchProducts_617569; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProducts
  ## Gets information about the products to which the caller has access.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617585 = newJObject()
  var body_617586 = newJObject()
  add(query_617585, "PageSize", newJString(PageSize))
  add(query_617585, "PageToken", newJString(PageToken))
  if body != nil:
    body_617586 = body
  result = call_617584.call(nil, query_617585, nil, nil, body_617586)

var searchProducts* = Call_SearchProducts_617569(name: "searchProducts",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts",
    validator: validate_SearchProducts_617570, base: "/", url: url_SearchProducts_617571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProductsAsAdmin_617587 = ref object of OpenApiRestCall_615866
proc url_SearchProductsAsAdmin_617589(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProductsAsAdmin_617588(path: JsonNode; query: JsonNode;
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
  var valid_617590 = query.getOrDefault("PageSize")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "PageSize", valid_617590
  var valid_617591 = query.getOrDefault("PageToken")
  valid_617591 = validateParameter(valid_617591, JString, required = false,
                                 default = nil)
  if valid_617591 != nil:
    section.add "PageToken", valid_617591
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617592 = header.getOrDefault("X-Amz-Date")
  valid_617592 = validateParameter(valid_617592, JString, required = false,
                                 default = nil)
  if valid_617592 != nil:
    section.add "X-Amz-Date", valid_617592
  var valid_617593 = header.getOrDefault("X-Amz-Security-Token")
  valid_617593 = validateParameter(valid_617593, JString, required = false,
                                 default = nil)
  if valid_617593 != nil:
    section.add "X-Amz-Security-Token", valid_617593
  var valid_617594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617594 = validateParameter(valid_617594, JString, required = false,
                                 default = nil)
  if valid_617594 != nil:
    section.add "X-Amz-Content-Sha256", valid_617594
  var valid_617595 = header.getOrDefault("X-Amz-Algorithm")
  valid_617595 = validateParameter(valid_617595, JString, required = false,
                                 default = nil)
  if valid_617595 != nil:
    section.add "X-Amz-Algorithm", valid_617595
  var valid_617596 = header.getOrDefault("X-Amz-Signature")
  valid_617596 = validateParameter(valid_617596, JString, required = false,
                                 default = nil)
  if valid_617596 != nil:
    section.add "X-Amz-Signature", valid_617596
  var valid_617597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617597 = validateParameter(valid_617597, JString, required = false,
                                 default = nil)
  if valid_617597 != nil:
    section.add "X-Amz-SignedHeaders", valid_617597
  var valid_617598 = header.getOrDefault("X-Amz-Target")
  valid_617598 = validateParameter(valid_617598, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProductsAsAdmin"))
  if valid_617598 != nil:
    section.add "X-Amz-Target", valid_617598
  var valid_617599 = header.getOrDefault("X-Amz-Credential")
  valid_617599 = validateParameter(valid_617599, JString, required = false,
                                 default = nil)
  if valid_617599 != nil:
    section.add "X-Amz-Credential", valid_617599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617601: Call_SearchProductsAsAdmin_617587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  let valid = call_617601.validator(path, query, header, formData, body)
  let scheme = call_617601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617601.url(scheme.get, call_617601.host, call_617601.base,
                         call_617601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617601, url, valid)

proc call*(call_617602: Call_SearchProductsAsAdmin_617587; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProductsAsAdmin
  ## Gets information about the products for the specified portfolio or all products.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617603 = newJObject()
  var body_617604 = newJObject()
  add(query_617603, "PageSize", newJString(PageSize))
  add(query_617603, "PageToken", newJString(PageToken))
  if body != nil:
    body_617604 = body
  result = call_617602.call(nil, query_617603, nil, nil, body_617604)

var searchProductsAsAdmin* = Call_SearchProductsAsAdmin_617587(
    name: "searchProductsAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin",
    validator: validate_SearchProductsAsAdmin_617588, base: "/",
    url: url_SearchProductsAsAdmin_617589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProvisionedProducts_617605 = ref object of OpenApiRestCall_615866
proc url_SearchProvisionedProducts_617607(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProvisionedProducts_617606(path: JsonNode; query: JsonNode;
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
  var valid_617608 = query.getOrDefault("PageSize")
  valid_617608 = validateParameter(valid_617608, JString, required = false,
                                 default = nil)
  if valid_617608 != nil:
    section.add "PageSize", valid_617608
  var valid_617609 = query.getOrDefault("PageToken")
  valid_617609 = validateParameter(valid_617609, JString, required = false,
                                 default = nil)
  if valid_617609 != nil:
    section.add "PageToken", valid_617609
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617610 = header.getOrDefault("X-Amz-Date")
  valid_617610 = validateParameter(valid_617610, JString, required = false,
                                 default = nil)
  if valid_617610 != nil:
    section.add "X-Amz-Date", valid_617610
  var valid_617611 = header.getOrDefault("X-Amz-Security-Token")
  valid_617611 = validateParameter(valid_617611, JString, required = false,
                                 default = nil)
  if valid_617611 != nil:
    section.add "X-Amz-Security-Token", valid_617611
  var valid_617612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617612 = validateParameter(valid_617612, JString, required = false,
                                 default = nil)
  if valid_617612 != nil:
    section.add "X-Amz-Content-Sha256", valid_617612
  var valid_617613 = header.getOrDefault("X-Amz-Algorithm")
  valid_617613 = validateParameter(valid_617613, JString, required = false,
                                 default = nil)
  if valid_617613 != nil:
    section.add "X-Amz-Algorithm", valid_617613
  var valid_617614 = header.getOrDefault("X-Amz-Signature")
  valid_617614 = validateParameter(valid_617614, JString, required = false,
                                 default = nil)
  if valid_617614 != nil:
    section.add "X-Amz-Signature", valid_617614
  var valid_617615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617615 = validateParameter(valid_617615, JString, required = false,
                                 default = nil)
  if valid_617615 != nil:
    section.add "X-Amz-SignedHeaders", valid_617615
  var valid_617616 = header.getOrDefault("X-Amz-Target")
  valid_617616 = validateParameter(valid_617616, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProvisionedProducts"))
  if valid_617616 != nil:
    section.add "X-Amz-Target", valid_617616
  var valid_617617 = header.getOrDefault("X-Amz-Credential")
  valid_617617 = validateParameter(valid_617617, JString, required = false,
                                 default = nil)
  if valid_617617 != nil:
    section.add "X-Amz-Credential", valid_617617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617619: Call_SearchProvisionedProducts_617605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  let valid = call_617619.validator(path, query, header, formData, body)
  let scheme = call_617619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617619.url(scheme.get, call_617619.host, call_617619.base,
                         call_617619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617619, url, valid)

proc call*(call_617620: Call_SearchProvisionedProducts_617605; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProvisionedProducts
  ## Gets information about the provisioned products that meet the specified criteria.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617621 = newJObject()
  var body_617622 = newJObject()
  add(query_617621, "PageSize", newJString(PageSize))
  add(query_617621, "PageToken", newJString(PageToken))
  if body != nil:
    body_617622 = body
  result = call_617620.call(nil, query_617621, nil, nil, body_617622)

var searchProvisionedProducts* = Call_SearchProvisionedProducts_617605(
    name: "searchProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts",
    validator: validate_SearchProvisionedProducts_617606, base: "/",
    url: url_SearchProvisionedProducts_617607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateProvisionedProduct_617623 = ref object of OpenApiRestCall_615866
proc url_TerminateProvisionedProduct_617625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateProvisionedProduct_617624(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617626 = header.getOrDefault("X-Amz-Date")
  valid_617626 = validateParameter(valid_617626, JString, required = false,
                                 default = nil)
  if valid_617626 != nil:
    section.add "X-Amz-Date", valid_617626
  var valid_617627 = header.getOrDefault("X-Amz-Security-Token")
  valid_617627 = validateParameter(valid_617627, JString, required = false,
                                 default = nil)
  if valid_617627 != nil:
    section.add "X-Amz-Security-Token", valid_617627
  var valid_617628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617628 = validateParameter(valid_617628, JString, required = false,
                                 default = nil)
  if valid_617628 != nil:
    section.add "X-Amz-Content-Sha256", valid_617628
  var valid_617629 = header.getOrDefault("X-Amz-Algorithm")
  valid_617629 = validateParameter(valid_617629, JString, required = false,
                                 default = nil)
  if valid_617629 != nil:
    section.add "X-Amz-Algorithm", valid_617629
  var valid_617630 = header.getOrDefault("X-Amz-Signature")
  valid_617630 = validateParameter(valid_617630, JString, required = false,
                                 default = nil)
  if valid_617630 != nil:
    section.add "X-Amz-Signature", valid_617630
  var valid_617631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617631 = validateParameter(valid_617631, JString, required = false,
                                 default = nil)
  if valid_617631 != nil:
    section.add "X-Amz-SignedHeaders", valid_617631
  var valid_617632 = header.getOrDefault("X-Amz-Target")
  valid_617632 = validateParameter(valid_617632, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.TerminateProvisionedProduct"))
  if valid_617632 != nil:
    section.add "X-Amz-Target", valid_617632
  var valid_617633 = header.getOrDefault("X-Amz-Credential")
  valid_617633 = validateParameter(valid_617633, JString, required = false,
                                 default = nil)
  if valid_617633 != nil:
    section.add "X-Amz-Credential", valid_617633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617635: Call_TerminateProvisionedProduct_617623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_617635.validator(path, query, header, formData, body)
  let scheme = call_617635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617635.url(scheme.get, call_617635.host, call_617635.base,
                         call_617635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617635, url, valid)

proc call*(call_617636: Call_TerminateProvisionedProduct_617623; body: JsonNode): Recallable =
  ## terminateProvisionedProduct
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_617637 = newJObject()
  if body != nil:
    body_617637 = body
  result = call_617636.call(nil, nil, nil, nil, body_617637)

var terminateProvisionedProduct* = Call_TerminateProvisionedProduct_617623(
    name: "terminateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct",
    validator: validate_TerminateProvisionedProduct_617624, base: "/",
    url: url_TerminateProvisionedProduct_617625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConstraint_617638 = ref object of OpenApiRestCall_615866
proc url_UpdateConstraint_617640(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConstraint_617639(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617641 = header.getOrDefault("X-Amz-Date")
  valid_617641 = validateParameter(valid_617641, JString, required = false,
                                 default = nil)
  if valid_617641 != nil:
    section.add "X-Amz-Date", valid_617641
  var valid_617642 = header.getOrDefault("X-Amz-Security-Token")
  valid_617642 = validateParameter(valid_617642, JString, required = false,
                                 default = nil)
  if valid_617642 != nil:
    section.add "X-Amz-Security-Token", valid_617642
  var valid_617643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617643 = validateParameter(valid_617643, JString, required = false,
                                 default = nil)
  if valid_617643 != nil:
    section.add "X-Amz-Content-Sha256", valid_617643
  var valid_617644 = header.getOrDefault("X-Amz-Algorithm")
  valid_617644 = validateParameter(valid_617644, JString, required = false,
                                 default = nil)
  if valid_617644 != nil:
    section.add "X-Amz-Algorithm", valid_617644
  var valid_617645 = header.getOrDefault("X-Amz-Signature")
  valid_617645 = validateParameter(valid_617645, JString, required = false,
                                 default = nil)
  if valid_617645 != nil:
    section.add "X-Amz-Signature", valid_617645
  var valid_617646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617646 = validateParameter(valid_617646, JString, required = false,
                                 default = nil)
  if valid_617646 != nil:
    section.add "X-Amz-SignedHeaders", valid_617646
  var valid_617647 = header.getOrDefault("X-Amz-Target")
  valid_617647 = validateParameter(valid_617647, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateConstraint"))
  if valid_617647 != nil:
    section.add "X-Amz-Target", valid_617647
  var valid_617648 = header.getOrDefault("X-Amz-Credential")
  valid_617648 = validateParameter(valid_617648, JString, required = false,
                                 default = nil)
  if valid_617648 != nil:
    section.add "X-Amz-Credential", valid_617648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617650: Call_UpdateConstraint_617638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified constraint.
  ## 
  let valid = call_617650.validator(path, query, header, formData, body)
  let scheme = call_617650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617650.url(scheme.get, call_617650.host, call_617650.base,
                         call_617650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617650, url, valid)

proc call*(call_617651: Call_UpdateConstraint_617638; body: JsonNode): Recallable =
  ## updateConstraint
  ## Updates the specified constraint.
  ##   body: JObject (required)
  var body_617652 = newJObject()
  if body != nil:
    body_617652 = body
  result = call_617651.call(nil, nil, nil, nil, body_617652)

var updateConstraint* = Call_UpdateConstraint_617638(name: "updateConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint",
    validator: validate_UpdateConstraint_617639, base: "/",
    url: url_UpdateConstraint_617640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePortfolio_617653 = ref object of OpenApiRestCall_615866
proc url_UpdatePortfolio_617655(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePortfolio_617654(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617656 = header.getOrDefault("X-Amz-Date")
  valid_617656 = validateParameter(valid_617656, JString, required = false,
                                 default = nil)
  if valid_617656 != nil:
    section.add "X-Amz-Date", valid_617656
  var valid_617657 = header.getOrDefault("X-Amz-Security-Token")
  valid_617657 = validateParameter(valid_617657, JString, required = false,
                                 default = nil)
  if valid_617657 != nil:
    section.add "X-Amz-Security-Token", valid_617657
  var valid_617658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617658 = validateParameter(valid_617658, JString, required = false,
                                 default = nil)
  if valid_617658 != nil:
    section.add "X-Amz-Content-Sha256", valid_617658
  var valid_617659 = header.getOrDefault("X-Amz-Algorithm")
  valid_617659 = validateParameter(valid_617659, JString, required = false,
                                 default = nil)
  if valid_617659 != nil:
    section.add "X-Amz-Algorithm", valid_617659
  var valid_617660 = header.getOrDefault("X-Amz-Signature")
  valid_617660 = validateParameter(valid_617660, JString, required = false,
                                 default = nil)
  if valid_617660 != nil:
    section.add "X-Amz-Signature", valid_617660
  var valid_617661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617661 = validateParameter(valid_617661, JString, required = false,
                                 default = nil)
  if valid_617661 != nil:
    section.add "X-Amz-SignedHeaders", valid_617661
  var valid_617662 = header.getOrDefault("X-Amz-Target")
  valid_617662 = validateParameter(valid_617662, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdatePortfolio"))
  if valid_617662 != nil:
    section.add "X-Amz-Target", valid_617662
  var valid_617663 = header.getOrDefault("X-Amz-Credential")
  valid_617663 = validateParameter(valid_617663, JString, required = false,
                                 default = nil)
  if valid_617663 != nil:
    section.add "X-Amz-Credential", valid_617663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617665: Call_UpdatePortfolio_617653; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ## 
  let valid = call_617665.validator(path, query, header, formData, body)
  let scheme = call_617665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617665.url(scheme.get, call_617665.host, call_617665.base,
                         call_617665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617665, url, valid)

proc call*(call_617666: Call_UpdatePortfolio_617653; body: JsonNode): Recallable =
  ## updatePortfolio
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_617667 = newJObject()
  if body != nil:
    body_617667 = body
  result = call_617666.call(nil, nil, nil, nil, body_617667)

var updatePortfolio* = Call_UpdatePortfolio_617653(name: "updatePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio",
    validator: validate_UpdatePortfolio_617654, base: "/", url: url_UpdatePortfolio_617655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProduct_617668 = ref object of OpenApiRestCall_615866
proc url_UpdateProduct_617670(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProduct_617669(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617671 = header.getOrDefault("X-Amz-Date")
  valid_617671 = validateParameter(valid_617671, JString, required = false,
                                 default = nil)
  if valid_617671 != nil:
    section.add "X-Amz-Date", valid_617671
  var valid_617672 = header.getOrDefault("X-Amz-Security-Token")
  valid_617672 = validateParameter(valid_617672, JString, required = false,
                                 default = nil)
  if valid_617672 != nil:
    section.add "X-Amz-Security-Token", valid_617672
  var valid_617673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617673 = validateParameter(valid_617673, JString, required = false,
                                 default = nil)
  if valid_617673 != nil:
    section.add "X-Amz-Content-Sha256", valid_617673
  var valid_617674 = header.getOrDefault("X-Amz-Algorithm")
  valid_617674 = validateParameter(valid_617674, JString, required = false,
                                 default = nil)
  if valid_617674 != nil:
    section.add "X-Amz-Algorithm", valid_617674
  var valid_617675 = header.getOrDefault("X-Amz-Signature")
  valid_617675 = validateParameter(valid_617675, JString, required = false,
                                 default = nil)
  if valid_617675 != nil:
    section.add "X-Amz-Signature", valid_617675
  var valid_617676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617676 = validateParameter(valid_617676, JString, required = false,
                                 default = nil)
  if valid_617676 != nil:
    section.add "X-Amz-SignedHeaders", valid_617676
  var valid_617677 = header.getOrDefault("X-Amz-Target")
  valid_617677 = validateParameter(valid_617677, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProduct"))
  if valid_617677 != nil:
    section.add "X-Amz-Target", valid_617677
  var valid_617678 = header.getOrDefault("X-Amz-Credential")
  valid_617678 = validateParameter(valid_617678, JString, required = false,
                                 default = nil)
  if valid_617678 != nil:
    section.add "X-Amz-Credential", valid_617678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617680: Call_UpdateProduct_617668; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified product.
  ## 
  let valid = call_617680.validator(path, query, header, formData, body)
  let scheme = call_617680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617680.url(scheme.get, call_617680.host, call_617680.base,
                         call_617680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617680, url, valid)

proc call*(call_617681: Call_UpdateProduct_617668; body: JsonNode): Recallable =
  ## updateProduct
  ## Updates the specified product.
  ##   body: JObject (required)
  var body_617682 = newJObject()
  if body != nil:
    body_617682 = body
  result = call_617681.call(nil, nil, nil, nil, body_617682)

var updateProduct* = Call_UpdateProduct_617668(name: "updateProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct",
    validator: validate_UpdateProduct_617669, base: "/", url: url_UpdateProduct_617670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProduct_617683 = ref object of OpenApiRestCall_615866
proc url_UpdateProvisionedProduct_617685(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisionedProduct_617684(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617686 = header.getOrDefault("X-Amz-Date")
  valid_617686 = validateParameter(valid_617686, JString, required = false,
                                 default = nil)
  if valid_617686 != nil:
    section.add "X-Amz-Date", valid_617686
  var valid_617687 = header.getOrDefault("X-Amz-Security-Token")
  valid_617687 = validateParameter(valid_617687, JString, required = false,
                                 default = nil)
  if valid_617687 != nil:
    section.add "X-Amz-Security-Token", valid_617687
  var valid_617688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617688 = validateParameter(valid_617688, JString, required = false,
                                 default = nil)
  if valid_617688 != nil:
    section.add "X-Amz-Content-Sha256", valid_617688
  var valid_617689 = header.getOrDefault("X-Amz-Algorithm")
  valid_617689 = validateParameter(valid_617689, JString, required = false,
                                 default = nil)
  if valid_617689 != nil:
    section.add "X-Amz-Algorithm", valid_617689
  var valid_617690 = header.getOrDefault("X-Amz-Signature")
  valid_617690 = validateParameter(valid_617690, JString, required = false,
                                 default = nil)
  if valid_617690 != nil:
    section.add "X-Amz-Signature", valid_617690
  var valid_617691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617691 = validateParameter(valid_617691, JString, required = false,
                                 default = nil)
  if valid_617691 != nil:
    section.add "X-Amz-SignedHeaders", valid_617691
  var valid_617692 = header.getOrDefault("X-Amz-Target")
  valid_617692 = validateParameter(valid_617692, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProduct"))
  if valid_617692 != nil:
    section.add "X-Amz-Target", valid_617692
  var valid_617693 = header.getOrDefault("X-Amz-Credential")
  valid_617693 = validateParameter(valid_617693, JString, required = false,
                                 default = nil)
  if valid_617693 != nil:
    section.add "X-Amz-Credential", valid_617693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617695: Call_UpdateProvisionedProduct_617683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_617695.validator(path, query, header, formData, body)
  let scheme = call_617695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617695.url(scheme.get, call_617695.host, call_617695.base,
                         call_617695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617695, url, valid)

proc call*(call_617696: Call_UpdateProvisionedProduct_617683; body: JsonNode): Recallable =
  ## updateProvisionedProduct
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_617697 = newJObject()
  if body != nil:
    body_617697 = body
  result = call_617696.call(nil, nil, nil, nil, body_617697)

var updateProvisionedProduct* = Call_UpdateProvisionedProduct_617683(
    name: "updateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct",
    validator: validate_UpdateProvisionedProduct_617684, base: "/",
    url: url_UpdateProvisionedProduct_617685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProductProperties_617698 = ref object of OpenApiRestCall_615866
proc url_UpdateProvisionedProductProperties_617700(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisionedProductProperties_617699(path: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617701 = header.getOrDefault("X-Amz-Date")
  valid_617701 = validateParameter(valid_617701, JString, required = false,
                                 default = nil)
  if valid_617701 != nil:
    section.add "X-Amz-Date", valid_617701
  var valid_617702 = header.getOrDefault("X-Amz-Security-Token")
  valid_617702 = validateParameter(valid_617702, JString, required = false,
                                 default = nil)
  if valid_617702 != nil:
    section.add "X-Amz-Security-Token", valid_617702
  var valid_617703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617703 = validateParameter(valid_617703, JString, required = false,
                                 default = nil)
  if valid_617703 != nil:
    section.add "X-Amz-Content-Sha256", valid_617703
  var valid_617704 = header.getOrDefault("X-Amz-Algorithm")
  valid_617704 = validateParameter(valid_617704, JString, required = false,
                                 default = nil)
  if valid_617704 != nil:
    section.add "X-Amz-Algorithm", valid_617704
  var valid_617705 = header.getOrDefault("X-Amz-Signature")
  valid_617705 = validateParameter(valid_617705, JString, required = false,
                                 default = nil)
  if valid_617705 != nil:
    section.add "X-Amz-Signature", valid_617705
  var valid_617706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617706 = validateParameter(valid_617706, JString, required = false,
                                 default = nil)
  if valid_617706 != nil:
    section.add "X-Amz-SignedHeaders", valid_617706
  var valid_617707 = header.getOrDefault("X-Amz-Target")
  valid_617707 = validateParameter(valid_617707, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProductProperties"))
  if valid_617707 != nil:
    section.add "X-Amz-Target", valid_617707
  var valid_617708 = header.getOrDefault("X-Amz-Credential")
  valid_617708 = validateParameter(valid_617708, JString, required = false,
                                 default = nil)
  if valid_617708 != nil:
    section.add "X-Amz-Credential", valid_617708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617710: Call_UpdateProvisionedProductProperties_617698;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests updates to the properties of the specified provisioned product.
  ## 
  let valid = call_617710.validator(path, query, header, formData, body)
  let scheme = call_617710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617710.url(scheme.get, call_617710.host, call_617710.base,
                         call_617710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617710, url, valid)

proc call*(call_617711: Call_UpdateProvisionedProductProperties_617698;
          body: JsonNode): Recallable =
  ## updateProvisionedProductProperties
  ## Requests updates to the properties of the specified provisioned product.
  ##   body: JObject (required)
  var body_617712 = newJObject()
  if body != nil:
    body_617712 = body
  result = call_617711.call(nil, nil, nil, nil, body_617712)

var updateProvisionedProductProperties* = Call_UpdateProvisionedProductProperties_617698(
    name: "updateProvisionedProductProperties", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties",
    validator: validate_UpdateProvisionedProductProperties_617699, base: "/",
    url: url_UpdateProvisionedProductProperties_617700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisioningArtifact_617713 = ref object of OpenApiRestCall_615866
proc url_UpdateProvisioningArtifact_617715(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisioningArtifact_617714(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617716 = header.getOrDefault("X-Amz-Date")
  valid_617716 = validateParameter(valid_617716, JString, required = false,
                                 default = nil)
  if valid_617716 != nil:
    section.add "X-Amz-Date", valid_617716
  var valid_617717 = header.getOrDefault("X-Amz-Security-Token")
  valid_617717 = validateParameter(valid_617717, JString, required = false,
                                 default = nil)
  if valid_617717 != nil:
    section.add "X-Amz-Security-Token", valid_617717
  var valid_617718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617718 = validateParameter(valid_617718, JString, required = false,
                                 default = nil)
  if valid_617718 != nil:
    section.add "X-Amz-Content-Sha256", valid_617718
  var valid_617719 = header.getOrDefault("X-Amz-Algorithm")
  valid_617719 = validateParameter(valid_617719, JString, required = false,
                                 default = nil)
  if valid_617719 != nil:
    section.add "X-Amz-Algorithm", valid_617719
  var valid_617720 = header.getOrDefault("X-Amz-Signature")
  valid_617720 = validateParameter(valid_617720, JString, required = false,
                                 default = nil)
  if valid_617720 != nil:
    section.add "X-Amz-Signature", valid_617720
  var valid_617721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617721 = validateParameter(valid_617721, JString, required = false,
                                 default = nil)
  if valid_617721 != nil:
    section.add "X-Amz-SignedHeaders", valid_617721
  var valid_617722 = header.getOrDefault("X-Amz-Target")
  valid_617722 = validateParameter(valid_617722, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisioningArtifact"))
  if valid_617722 != nil:
    section.add "X-Amz-Target", valid_617722
  var valid_617723 = header.getOrDefault("X-Amz-Credential")
  valid_617723 = validateParameter(valid_617723, JString, required = false,
                                 default = nil)
  if valid_617723 != nil:
    section.add "X-Amz-Credential", valid_617723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617725: Call_UpdateProvisioningArtifact_617713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_617725.validator(path, query, header, formData, body)
  let scheme = call_617725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617725.url(scheme.get, call_617725.host, call_617725.base,
                         call_617725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617725, url, valid)

proc call*(call_617726: Call_UpdateProvisioningArtifact_617713; body: JsonNode): Recallable =
  ## updateProvisioningArtifact
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_617727 = newJObject()
  if body != nil:
    body_617727 = body
  result = call_617726.call(nil, nil, nil, nil, body_617727)

var updateProvisioningArtifact* = Call_UpdateProvisioningArtifact_617713(
    name: "updateProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact",
    validator: validate_UpdateProvisioningArtifact_617714, base: "/",
    url: url_UpdateProvisioningArtifact_617715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceAction_617728 = ref object of OpenApiRestCall_615866
proc url_UpdateServiceAction_617730(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServiceAction_617729(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617731 = header.getOrDefault("X-Amz-Date")
  valid_617731 = validateParameter(valid_617731, JString, required = false,
                                 default = nil)
  if valid_617731 != nil:
    section.add "X-Amz-Date", valid_617731
  var valid_617732 = header.getOrDefault("X-Amz-Security-Token")
  valid_617732 = validateParameter(valid_617732, JString, required = false,
                                 default = nil)
  if valid_617732 != nil:
    section.add "X-Amz-Security-Token", valid_617732
  var valid_617733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617733 = validateParameter(valid_617733, JString, required = false,
                                 default = nil)
  if valid_617733 != nil:
    section.add "X-Amz-Content-Sha256", valid_617733
  var valid_617734 = header.getOrDefault("X-Amz-Algorithm")
  valid_617734 = validateParameter(valid_617734, JString, required = false,
                                 default = nil)
  if valid_617734 != nil:
    section.add "X-Amz-Algorithm", valid_617734
  var valid_617735 = header.getOrDefault("X-Amz-Signature")
  valid_617735 = validateParameter(valid_617735, JString, required = false,
                                 default = nil)
  if valid_617735 != nil:
    section.add "X-Amz-Signature", valid_617735
  var valid_617736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617736 = validateParameter(valid_617736, JString, required = false,
                                 default = nil)
  if valid_617736 != nil:
    section.add "X-Amz-SignedHeaders", valid_617736
  var valid_617737 = header.getOrDefault("X-Amz-Target")
  valid_617737 = validateParameter(valid_617737, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateServiceAction"))
  if valid_617737 != nil:
    section.add "X-Amz-Target", valid_617737
  var valid_617738 = header.getOrDefault("X-Amz-Credential")
  valid_617738 = validateParameter(valid_617738, JString, required = false,
                                 default = nil)
  if valid_617738 != nil:
    section.add "X-Amz-Credential", valid_617738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617740: Call_UpdateServiceAction_617728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a self-service action.
  ## 
  let valid = call_617740.validator(path, query, header, formData, body)
  let scheme = call_617740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617740.url(scheme.get, call_617740.host, call_617740.base,
                         call_617740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617740, url, valid)

proc call*(call_617741: Call_UpdateServiceAction_617728; body: JsonNode): Recallable =
  ## updateServiceAction
  ## Updates a self-service action.
  ##   body: JObject (required)
  var body_617742 = newJObject()
  if body != nil:
    body_617742 = body
  result = call_617741.call(nil, nil, nil, nil, body_617742)

var updateServiceAction* = Call_UpdateServiceAction_617728(
    name: "updateServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction",
    validator: validate_UpdateServiceAction_617729, base: "/",
    url: url_UpdateServiceAction_617730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagOption_617743 = ref object of OpenApiRestCall_615866
proc url_UpdateTagOption_617745(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTagOption_617744(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617746 = header.getOrDefault("X-Amz-Date")
  valid_617746 = validateParameter(valid_617746, JString, required = false,
                                 default = nil)
  if valid_617746 != nil:
    section.add "X-Amz-Date", valid_617746
  var valid_617747 = header.getOrDefault("X-Amz-Security-Token")
  valid_617747 = validateParameter(valid_617747, JString, required = false,
                                 default = nil)
  if valid_617747 != nil:
    section.add "X-Amz-Security-Token", valid_617747
  var valid_617748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617748 = validateParameter(valid_617748, JString, required = false,
                                 default = nil)
  if valid_617748 != nil:
    section.add "X-Amz-Content-Sha256", valid_617748
  var valid_617749 = header.getOrDefault("X-Amz-Algorithm")
  valid_617749 = validateParameter(valid_617749, JString, required = false,
                                 default = nil)
  if valid_617749 != nil:
    section.add "X-Amz-Algorithm", valid_617749
  var valid_617750 = header.getOrDefault("X-Amz-Signature")
  valid_617750 = validateParameter(valid_617750, JString, required = false,
                                 default = nil)
  if valid_617750 != nil:
    section.add "X-Amz-Signature", valid_617750
  var valid_617751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617751 = validateParameter(valid_617751, JString, required = false,
                                 default = nil)
  if valid_617751 != nil:
    section.add "X-Amz-SignedHeaders", valid_617751
  var valid_617752 = header.getOrDefault("X-Amz-Target")
  valid_617752 = validateParameter(valid_617752, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateTagOption"))
  if valid_617752 != nil:
    section.add "X-Amz-Target", valid_617752
  var valid_617753 = header.getOrDefault("X-Amz-Credential")
  valid_617753 = validateParameter(valid_617753, JString, required = false,
                                 default = nil)
  if valid_617753 != nil:
    section.add "X-Amz-Credential", valid_617753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617755: Call_UpdateTagOption_617743; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified TagOption.
  ## 
  let valid = call_617755.validator(path, query, header, formData, body)
  let scheme = call_617755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617755.url(scheme.get, call_617755.host, call_617755.base,
                         call_617755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617755, url, valid)

proc call*(call_617756: Call_UpdateTagOption_617743; body: JsonNode): Recallable =
  ## updateTagOption
  ## Updates the specified TagOption.
  ##   body: JObject (required)
  var body_617757 = newJObject()
  if body != nil:
    body_617757 = body
  result = call_617756.call(nil, nil, nil, nil, body_617757)

var updateTagOption* = Call_UpdateTagOption_617743(name: "updateTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption",
    validator: validate_UpdateTagOption_617744, base: "/", url: url_UpdateTagOption_617745,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
