
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AcceptPortfolioShare_21625779 = ref object of OpenApiRestCall_21625435
proc url_AcceptPortfolioShare_21625781(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptPortfolioShare_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AcceptPortfolioShare"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625929: Call_AcceptPortfolioShare_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Accepts an offer to share the specified portfolio.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AcceptPortfolioShare_21625779; body: JsonNode): Recallable =
  ## acceptPortfolioShare
  ## Accepts an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var acceptPortfolioShare* = Call_AcceptPortfolioShare_21625779(
    name: "acceptPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare",
    validator: validate_AcceptPortfolioShare_21625780, base: "/",
    makeUrl: url_AcceptPortfolioShare_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateBudgetWithResource_21626029 = ref object of OpenApiRestCall_21625435
proc url_AssociateBudgetWithResource_21626031(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateBudgetWithResource_21626030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateBudgetWithResource"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_AssociateBudgetWithResource_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified budget with the specified resource.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_AssociateBudgetWithResource_21626029; body: JsonNode): Recallable =
  ## associateBudgetWithResource
  ## Associates the specified budget with the specified resource.
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var associateBudgetWithResource* = Call_AssociateBudgetWithResource_21626029(
    name: "associateBudgetWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource",
    validator: validate_AssociateBudgetWithResource_21626030, base: "/",
    makeUrl: url_AssociateBudgetWithResource_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePrincipalWithPortfolio_21626044 = ref object of OpenApiRestCall_21625435
proc url_AssociatePrincipalWithPortfolio_21626046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociatePrincipalWithPortfolio_21626045(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626056: Call_AssociatePrincipalWithPortfolio_21626044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified principal ARN with the specified portfolio.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_AssociatePrincipalWithPortfolio_21626044;
          body: JsonNode): Recallable =
  ## associatePrincipalWithPortfolio
  ## Associates the specified principal ARN with the specified portfolio.
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var associatePrincipalWithPortfolio* = Call_AssociatePrincipalWithPortfolio_21626044(
    name: "associatePrincipalWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio",
    validator: validate_AssociatePrincipalWithPortfolio_21626045, base: "/",
    makeUrl: url_AssociatePrincipalWithPortfolio_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateProductWithPortfolio_21626059 = ref object of OpenApiRestCall_21625435
proc url_AssociateProductWithPortfolio_21626061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateProductWithPortfolio_21626060(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateProductWithPortfolio"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626071: Call_AssociateProductWithPortfolio_21626059;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified product with the specified portfolio.
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_AssociateProductWithPortfolio_21626059;
          body: JsonNode): Recallable =
  ## associateProductWithPortfolio
  ## Associates the specified product with the specified portfolio.
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var associateProductWithPortfolio* = Call_AssociateProductWithPortfolio_21626059(
    name: "associateProductWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio",
    validator: validate_AssociateProductWithPortfolio_21626060, base: "/",
    makeUrl: url_AssociateProductWithPortfolio_21626061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceActionWithProvisioningArtifact_21626074 = ref object of OpenApiRestCall_21625435
proc url_AssociateServiceActionWithProvisioningArtifact_21626076(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceActionWithProvisioningArtifact_21626075(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString("AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_AssociateServiceActionWithProvisioningArtifact_21626074;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a self-service action with a provisioning artifact.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_AssociateServiceActionWithProvisioningArtifact_21626074;
          body: JsonNode): Recallable =
  ## associateServiceActionWithProvisioningArtifact
  ## Associates a self-service action with a provisioning artifact.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var associateServiceActionWithProvisioningArtifact* = Call_AssociateServiceActionWithProvisioningArtifact_21626074(
    name: "associateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact",
    validator: validate_AssociateServiceActionWithProvisioningArtifact_21626075,
    base: "/", makeUrl: url_AssociateServiceActionWithProvisioningArtifact_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTagOptionWithResource_21626089 = ref object of OpenApiRestCall_21625435
proc url_AssociateTagOptionWithResource_21626091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateTagOptionWithResource_21626090(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateTagOptionWithResource"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626101: Call_AssociateTagOptionWithResource_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associate the specified TagOption with the specified portfolio or product.
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_AssociateTagOptionWithResource_21626089;
          body: JsonNode): Recallable =
  ## associateTagOptionWithResource
  ## Associate the specified TagOption with the specified portfolio or product.
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var associateTagOptionWithResource* = Call_AssociateTagOptionWithResource_21626089(
    name: "associateTagOptionWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource",
    validator: validate_AssociateTagOptionWithResource_21626090, base: "/",
    makeUrl: url_AssociateTagOptionWithResource_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateServiceActionWithProvisioningArtifact_21626104 = ref object of OpenApiRestCall_21625435
proc url_BatchAssociateServiceActionWithProvisioningArtifact_21626106(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchAssociateServiceActionWithProvisioningArtifact_21626105(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626116: Call_BatchAssociateServiceActionWithProvisioningArtifact_21626104;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates multiple self-service actions with provisioning artifacts.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_BatchAssociateServiceActionWithProvisioningArtifact_21626104;
          body: JsonNode): Recallable =
  ## batchAssociateServiceActionWithProvisioningArtifact
  ## Associates multiple self-service actions with provisioning artifacts.
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var batchAssociateServiceActionWithProvisioningArtifact* = Call_BatchAssociateServiceActionWithProvisioningArtifact_21626104(
    name: "batchAssociateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact",
    validator: validate_BatchAssociateServiceActionWithProvisioningArtifact_21626105,
    base: "/", makeUrl: url_BatchAssociateServiceActionWithProvisioningArtifact_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateServiceActionFromProvisioningArtifact_21626119 = ref object of OpenApiRestCall_21625435
proc url_BatchDisassociateServiceActionFromProvisioningArtifact_21626121(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisassociateServiceActionFromProvisioningArtifact_21626120(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626131: Call_BatchDisassociateServiceActionFromProvisioningArtifact_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_BatchDisassociateServiceActionFromProvisioningArtifact_21626119;
          body: JsonNode): Recallable =
  ## batchDisassociateServiceActionFromProvisioningArtifact
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var batchDisassociateServiceActionFromProvisioningArtifact* = Call_BatchDisassociateServiceActionFromProvisioningArtifact_21626119(
    name: "batchDisassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact",
    validator: validate_BatchDisassociateServiceActionFromProvisioningArtifact_21626120,
    base: "/",
    makeUrl: url_BatchDisassociateServiceActionFromProvisioningArtifact_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyProduct_21626134 = ref object of OpenApiRestCall_21625435
proc url_CopyProduct_21626136(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CopyProduct_21626135(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CopyProduct"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626146: Call_CopyProduct_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_CopyProduct_21626134; body: JsonNode): Recallable =
  ## copyProduct
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var copyProduct* = Call_CopyProduct_21626134(name: "copyProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct",
    validator: validate_CopyProduct_21626135, base: "/", makeUrl: url_CopyProduct_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConstraint_21626149 = ref object of OpenApiRestCall_21625435
proc url_CreateConstraint_21626151(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConstraint_21626150(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateConstraint"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626161: Call_CreateConstraint_21626149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a constraint.
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_CreateConstraint_21626149; body: JsonNode): Recallable =
  ## createConstraint
  ## Creates a constraint.
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var createConstraint* = Call_CreateConstraint_21626149(name: "createConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint",
    validator: validate_CreateConstraint_21626150, base: "/",
    makeUrl: url_CreateConstraint_21626151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolio_21626164 = ref object of OpenApiRestCall_21625435
proc url_CreatePortfolio_21626166(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePortfolio_21626165(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolio"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626176: Call_CreatePortfolio_21626164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a portfolio.
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_CreatePortfolio_21626164; body: JsonNode): Recallable =
  ## createPortfolio
  ## Creates a portfolio.
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var createPortfolio* = Call_CreatePortfolio_21626164(name: "createPortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio",
    validator: validate_CreatePortfolio_21626165, base: "/",
    makeUrl: url_CreatePortfolio_21626166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolioShare_21626179 = ref object of OpenApiRestCall_21625435
proc url_CreatePortfolioShare_21626181(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePortfolioShare_21626180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolioShare"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626191: Call_CreatePortfolioShare_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_CreatePortfolioShare_21626179; body: JsonNode): Recallable =
  ## createPortfolioShare
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var createPortfolioShare* = Call_CreatePortfolioShare_21626179(
    name: "createPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare",
    validator: validate_CreatePortfolioShare_21626180, base: "/",
    makeUrl: url_CreatePortfolioShare_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProduct_21626194 = ref object of OpenApiRestCall_21625435
proc url_CreateProduct_21626196(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProduct_21626195(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProduct"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626206: Call_CreateProduct_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a product.
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_CreateProduct_21626194; body: JsonNode): Recallable =
  ## createProduct
  ## Creates a product.
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var createProduct* = Call_CreateProduct_21626194(name: "createProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct",
    validator: validate_CreateProduct_21626195, base: "/",
    makeUrl: url_CreateProduct_21626196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisionedProductPlan_21626209 = ref object of OpenApiRestCall_21625435
proc url_CreateProvisionedProductPlan_21626211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProvisionedProductPlan_21626210(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisionedProductPlan"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626221: Call_CreateProvisionedProductPlan_21626209;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_CreateProvisionedProductPlan_21626209;
          body: JsonNode): Recallable =
  ## createProvisionedProductPlan
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var createProvisionedProductPlan* = Call_CreateProvisionedProductPlan_21626209(
    name: "createProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan",
    validator: validate_CreateProvisionedProductPlan_21626210, base: "/",
    makeUrl: url_CreateProvisionedProductPlan_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisioningArtifact_21626224 = ref object of OpenApiRestCall_21625435
proc url_CreateProvisioningArtifact_21626226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProvisioningArtifact_21626225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisioningArtifact"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626236: Call_CreateProvisioningArtifact_21626224;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_CreateProvisioningArtifact_21626224; body: JsonNode): Recallable =
  ## createProvisioningArtifact
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var createProvisioningArtifact* = Call_CreateProvisioningArtifact_21626224(
    name: "createProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact",
    validator: validate_CreateProvisioningArtifact_21626225, base: "/",
    makeUrl: url_CreateProvisioningArtifact_21626226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServiceAction_21626239 = ref object of OpenApiRestCall_21625435
proc url_CreateServiceAction_21626241(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateServiceAction_21626240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626242 = header.getOrDefault("X-Amz-Date")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Date", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Security-Token", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Target")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateServiceAction"))
  if valid_21626244 != nil:
    section.add "X-Amz-Target", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626251: Call_CreateServiceAction_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a self-service action.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_CreateServiceAction_21626239; body: JsonNode): Recallable =
  ## createServiceAction
  ## Creates a self-service action.
  ##   body: JObject (required)
  var body_21626253 = newJObject()
  if body != nil:
    body_21626253 = body
  result = call_21626252.call(nil, nil, nil, nil, body_21626253)

var createServiceAction* = Call_CreateServiceAction_21626239(
    name: "createServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction",
    validator: validate_CreateServiceAction_21626240, base: "/",
    makeUrl: url_CreateServiceAction_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTagOption_21626254 = ref object of OpenApiRestCall_21625435
proc url_CreateTagOption_21626256(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTagOption_21626255(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626257 = header.getOrDefault("X-Amz-Date")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Date", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Security-Token", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Target")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateTagOption"))
  if valid_21626259 != nil:
    section.add "X-Amz-Target", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626266: Call_CreateTagOption_21626254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a TagOption.
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_CreateTagOption_21626254; body: JsonNode): Recallable =
  ## createTagOption
  ## Creates a TagOption.
  ##   body: JObject (required)
  var body_21626268 = newJObject()
  if body != nil:
    body_21626268 = body
  result = call_21626267.call(nil, nil, nil, nil, body_21626268)

var createTagOption* = Call_CreateTagOption_21626254(name: "createTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption",
    validator: validate_CreateTagOption_21626255, base: "/",
    makeUrl: url_CreateTagOption_21626256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConstraint_21626269 = ref object of OpenApiRestCall_21625435
proc url_DeleteConstraint_21626271(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConstraint_21626270(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Target")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteConstraint"))
  if valid_21626274 != nil:
    section.add "X-Amz-Target", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626281: Call_DeleteConstraint_21626269; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified constraint.
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_DeleteConstraint_21626269; body: JsonNode): Recallable =
  ## deleteConstraint
  ## Deletes the specified constraint.
  ##   body: JObject (required)
  var body_21626283 = newJObject()
  if body != nil:
    body_21626283 = body
  result = call_21626282.call(nil, nil, nil, nil, body_21626283)

var deleteConstraint* = Call_DeleteConstraint_21626269(name: "deleteConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint",
    validator: validate_DeleteConstraint_21626270, base: "/",
    makeUrl: url_DeleteConstraint_21626271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolio_21626284 = ref object of OpenApiRestCall_21625435
proc url_DeletePortfolio_21626286(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePortfolio_21626285(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626287 = header.getOrDefault("X-Amz-Date")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Date", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Security-Token", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Target")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolio"))
  if valid_21626289 != nil:
    section.add "X-Amz-Target", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626296: Call_DeletePortfolio_21626284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_DeletePortfolio_21626284; body: JsonNode): Recallable =
  ## deletePortfolio
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ##   body: JObject (required)
  var body_21626298 = newJObject()
  if body != nil:
    body_21626298 = body
  result = call_21626297.call(nil, nil, nil, nil, body_21626298)

var deletePortfolio* = Call_DeletePortfolio_21626284(name: "deletePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio",
    validator: validate_DeletePortfolio_21626285, base: "/",
    makeUrl: url_DeletePortfolio_21626286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolioShare_21626299 = ref object of OpenApiRestCall_21625435
proc url_DeletePortfolioShare_21626301(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePortfolioShare_21626300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626302 = header.getOrDefault("X-Amz-Date")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Date", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Security-Token", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Target")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolioShare"))
  if valid_21626304 != nil:
    section.add "X-Amz-Target", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626311: Call_DeletePortfolioShare_21626299; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_DeletePortfolioShare_21626299; body: JsonNode): Recallable =
  ## deletePortfolioShare
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ##   body: JObject (required)
  var body_21626313 = newJObject()
  if body != nil:
    body_21626313 = body
  result = call_21626312.call(nil, nil, nil, nil, body_21626313)

var deletePortfolioShare* = Call_DeletePortfolioShare_21626299(
    name: "deletePortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare",
    validator: validate_DeletePortfolioShare_21626300, base: "/",
    makeUrl: url_DeletePortfolioShare_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProduct_21626314 = ref object of OpenApiRestCall_21625435
proc url_DeleteProduct_21626316(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProduct_21626315(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Target")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProduct"))
  if valid_21626319 != nil:
    section.add "X-Amz-Target", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626326: Call_DeleteProduct_21626314; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_DeleteProduct_21626314; body: JsonNode): Recallable =
  ## deleteProduct
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ##   body: JObject (required)
  var body_21626328 = newJObject()
  if body != nil:
    body_21626328 = body
  result = call_21626327.call(nil, nil, nil, nil, body_21626328)

var deleteProduct* = Call_DeleteProduct_21626314(name: "deleteProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct",
    validator: validate_DeleteProduct_21626315, base: "/",
    makeUrl: url_DeleteProduct_21626316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedProductPlan_21626329 = ref object of OpenApiRestCall_21625435
proc url_DeleteProvisionedProductPlan_21626331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProvisionedProductPlan_21626330(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Target")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisionedProductPlan"))
  if valid_21626334 != nil:
    section.add "X-Amz-Target", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626341: Call_DeleteProvisionedProductPlan_21626329;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified plan.
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_DeleteProvisionedProductPlan_21626329;
          body: JsonNode): Recallable =
  ## deleteProvisionedProductPlan
  ## Deletes the specified plan.
  ##   body: JObject (required)
  var body_21626343 = newJObject()
  if body != nil:
    body_21626343 = body
  result = call_21626342.call(nil, nil, nil, nil, body_21626343)

var deleteProvisionedProductPlan* = Call_DeleteProvisionedProductPlan_21626329(
    name: "deleteProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan",
    validator: validate_DeleteProvisionedProductPlan_21626330, base: "/",
    makeUrl: url_DeleteProvisionedProductPlan_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisioningArtifact_21626344 = ref object of OpenApiRestCall_21625435
proc url_DeleteProvisioningArtifact_21626346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProvisioningArtifact_21626345(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Target")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisioningArtifact"))
  if valid_21626349 != nil:
    section.add "X-Amz-Target", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626356: Call_DeleteProvisioningArtifact_21626344;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_DeleteProvisioningArtifact_21626344; body: JsonNode): Recallable =
  ## deleteProvisioningArtifact
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ##   body: JObject (required)
  var body_21626358 = newJObject()
  if body != nil:
    body_21626358 = body
  result = call_21626357.call(nil, nil, nil, nil, body_21626358)

var deleteProvisioningArtifact* = Call_DeleteProvisioningArtifact_21626344(
    name: "deleteProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact",
    validator: validate_DeleteProvisioningArtifact_21626345, base: "/",
    makeUrl: url_DeleteProvisioningArtifact_21626346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceAction_21626359 = ref object of OpenApiRestCall_21625435
proc url_DeleteServiceAction_21626361(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServiceAction_21626360(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Target")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteServiceAction"))
  if valid_21626364 != nil:
    section.add "X-Amz-Target", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Algorithm", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Signature")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Signature", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Credential")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Credential", valid_21626369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626371: Call_DeleteServiceAction_21626359; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a self-service action.
  ## 
  let valid = call_21626371.validator(path, query, header, formData, body, _)
  let scheme = call_21626371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626371.makeUrl(scheme.get, call_21626371.host, call_21626371.base,
                               call_21626371.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626371, uri, valid, _)

proc call*(call_21626372: Call_DeleteServiceAction_21626359; body: JsonNode): Recallable =
  ## deleteServiceAction
  ## Deletes a self-service action.
  ##   body: JObject (required)
  var body_21626373 = newJObject()
  if body != nil:
    body_21626373 = body
  result = call_21626372.call(nil, nil, nil, nil, body_21626373)

var deleteServiceAction* = Call_DeleteServiceAction_21626359(
    name: "deleteServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction",
    validator: validate_DeleteServiceAction_21626360, base: "/",
    makeUrl: url_DeleteServiceAction_21626361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagOption_21626374 = ref object of OpenApiRestCall_21625435
proc url_DeleteTagOption_21626376(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTagOption_21626375(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626377 = header.getOrDefault("X-Amz-Date")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Date", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Security-Token", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Target")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteTagOption"))
  if valid_21626379 != nil:
    section.add "X-Amz-Target", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626386: Call_DeleteTagOption_21626374; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ## 
  let valid = call_21626386.validator(path, query, header, formData, body, _)
  let scheme = call_21626386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626386.makeUrl(scheme.get, call_21626386.host, call_21626386.base,
                               call_21626386.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626386, uri, valid, _)

proc call*(call_21626387: Call_DeleteTagOption_21626374; body: JsonNode): Recallable =
  ## deleteTagOption
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ##   body: JObject (required)
  var body_21626388 = newJObject()
  if body != nil:
    body_21626388 = body
  result = call_21626387.call(nil, nil, nil, nil, body_21626388)

var deleteTagOption* = Call_DeleteTagOption_21626374(name: "deleteTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption",
    validator: validate_DeleteTagOption_21626375, base: "/",
    makeUrl: url_DeleteTagOption_21626376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConstraint_21626389 = ref object of OpenApiRestCall_21625435
proc url_DescribeConstraint_21626391(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConstraint_21626390(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626392 = header.getOrDefault("X-Amz-Date")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Date", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Security-Token", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Target")
  valid_21626394 = validateParameter(valid_21626394, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeConstraint"))
  if valid_21626394 != nil:
    section.add "X-Amz-Target", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Algorithm", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Signature")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Signature", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Credential")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Credential", valid_21626399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626401: Call_DescribeConstraint_21626389; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified constraint.
  ## 
  let valid = call_21626401.validator(path, query, header, formData, body, _)
  let scheme = call_21626401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626401.makeUrl(scheme.get, call_21626401.host, call_21626401.base,
                               call_21626401.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626401, uri, valid, _)

proc call*(call_21626402: Call_DescribeConstraint_21626389; body: JsonNode): Recallable =
  ## describeConstraint
  ## Gets information about the specified constraint.
  ##   body: JObject (required)
  var body_21626403 = newJObject()
  if body != nil:
    body_21626403 = body
  result = call_21626402.call(nil, nil, nil, nil, body_21626403)

var describeConstraint* = Call_DescribeConstraint_21626389(
    name: "describeConstraint", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint",
    validator: validate_DescribeConstraint_21626390, base: "/",
    makeUrl: url_DescribeConstraint_21626391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyProductStatus_21626404 = ref object of OpenApiRestCall_21625435
proc url_DescribeCopyProductStatus_21626406(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCopyProductStatus_21626405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626407 = header.getOrDefault("X-Amz-Date")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Date", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Security-Token", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Target")
  valid_21626409 = validateParameter(valid_21626409, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeCopyProductStatus"))
  if valid_21626409 != nil:
    section.add "X-Amz-Target", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Algorithm", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Signature")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Signature", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Credential")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Credential", valid_21626414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626416: Call_DescribeCopyProductStatus_21626404;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the status of the specified copy product operation.
  ## 
  let valid = call_21626416.validator(path, query, header, formData, body, _)
  let scheme = call_21626416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626416.makeUrl(scheme.get, call_21626416.host, call_21626416.base,
                               call_21626416.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626416, uri, valid, _)

proc call*(call_21626417: Call_DescribeCopyProductStatus_21626404; body: JsonNode): Recallable =
  ## describeCopyProductStatus
  ## Gets the status of the specified copy product operation.
  ##   body: JObject (required)
  var body_21626418 = newJObject()
  if body != nil:
    body_21626418 = body
  result = call_21626417.call(nil, nil, nil, nil, body_21626418)

var describeCopyProductStatus* = Call_DescribeCopyProductStatus_21626404(
    name: "describeCopyProductStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus",
    validator: validate_DescribeCopyProductStatus_21626405, base: "/",
    makeUrl: url_DescribeCopyProductStatus_21626406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolio_21626419 = ref object of OpenApiRestCall_21625435
proc url_DescribePortfolio_21626421(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePortfolio_21626420(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626422 = header.getOrDefault("X-Amz-Date")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Date", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Security-Token", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Target")
  valid_21626424 = validateParameter(valid_21626424, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolio"))
  if valid_21626424 != nil:
    section.add "X-Amz-Target", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Algorithm", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Signature")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Signature", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Credential")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Credential", valid_21626429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626431: Call_DescribePortfolio_21626419; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified portfolio.
  ## 
  let valid = call_21626431.validator(path, query, header, formData, body, _)
  let scheme = call_21626431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626431.makeUrl(scheme.get, call_21626431.host, call_21626431.base,
                               call_21626431.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626431, uri, valid, _)

proc call*(call_21626432: Call_DescribePortfolio_21626419; body: JsonNode): Recallable =
  ## describePortfolio
  ## Gets information about the specified portfolio.
  ##   body: JObject (required)
  var body_21626433 = newJObject()
  if body != nil:
    body_21626433 = body
  result = call_21626432.call(nil, nil, nil, nil, body_21626433)

var describePortfolio* = Call_DescribePortfolio_21626419(name: "describePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio",
    validator: validate_DescribePortfolio_21626420, base: "/",
    makeUrl: url_DescribePortfolio_21626421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolioShareStatus_21626434 = ref object of OpenApiRestCall_21625435
proc url_DescribePortfolioShareStatus_21626436(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePortfolioShareStatus_21626435(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626437 = header.getOrDefault("X-Amz-Date")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Date", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Security-Token", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Target")
  valid_21626439 = validateParameter(valid_21626439, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolioShareStatus"))
  if valid_21626439 != nil:
    section.add "X-Amz-Target", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Algorithm", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Signature")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Signature", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Credential")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Credential", valid_21626444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626446: Call_DescribePortfolioShareStatus_21626434;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ## 
  let valid = call_21626446.validator(path, query, header, formData, body, _)
  let scheme = call_21626446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626446.makeUrl(scheme.get, call_21626446.host, call_21626446.base,
                               call_21626446.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626446, uri, valid, _)

proc call*(call_21626447: Call_DescribePortfolioShareStatus_21626434;
          body: JsonNode): Recallable =
  ## describePortfolioShareStatus
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_21626448 = newJObject()
  if body != nil:
    body_21626448 = body
  result = call_21626447.call(nil, nil, nil, nil, body_21626448)

var describePortfolioShareStatus* = Call_DescribePortfolioShareStatus_21626434(
    name: "describePortfolioShareStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus",
    validator: validate_DescribePortfolioShareStatus_21626435, base: "/",
    makeUrl: url_DescribePortfolioShareStatus_21626436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProduct_21626449 = ref object of OpenApiRestCall_21625435
proc url_DescribeProduct_21626451(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProduct_21626450(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626452 = header.getOrDefault("X-Amz-Date")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Date", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Security-Token", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Target")
  valid_21626454 = validateParameter(valid_21626454, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProduct"))
  if valid_21626454 != nil:
    section.add "X-Amz-Target", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Algorithm", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Signature")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Signature", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Credential")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Credential", valid_21626459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626461: Call_DescribeProduct_21626449; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_DescribeProduct_21626449; body: JsonNode): Recallable =
  ## describeProduct
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_21626463 = newJObject()
  if body != nil:
    body_21626463 = body
  result = call_21626462.call(nil, nil, nil, nil, body_21626463)

var describeProduct* = Call_DescribeProduct_21626449(name: "describeProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct",
    validator: validate_DescribeProduct_21626450, base: "/",
    makeUrl: url_DescribeProduct_21626451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductAsAdmin_21626464 = ref object of OpenApiRestCall_21625435
proc url_DescribeProductAsAdmin_21626466(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProductAsAdmin_21626465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626467 = header.getOrDefault("X-Amz-Date")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Date", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Security-Token", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Target")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductAsAdmin"))
  if valid_21626469 != nil:
    section.add "X-Amz-Target", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Algorithm", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Signature")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Signature", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Credential")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Credential", valid_21626474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626476: Call_DescribeProductAsAdmin_21626464;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified product. This operation is run with administrator access.
  ## 
  let valid = call_21626476.validator(path, query, header, formData, body, _)
  let scheme = call_21626476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626476.makeUrl(scheme.get, call_21626476.host, call_21626476.base,
                               call_21626476.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626476, uri, valid, _)

proc call*(call_21626477: Call_DescribeProductAsAdmin_21626464; body: JsonNode): Recallable =
  ## describeProductAsAdmin
  ## Gets information about the specified product. This operation is run with administrator access.
  ##   body: JObject (required)
  var body_21626478 = newJObject()
  if body != nil:
    body_21626478 = body
  result = call_21626477.call(nil, nil, nil, nil, body_21626478)

var describeProductAsAdmin* = Call_DescribeProductAsAdmin_21626464(
    name: "describeProductAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin",
    validator: validate_DescribeProductAsAdmin_21626465, base: "/",
    makeUrl: url_DescribeProductAsAdmin_21626466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductView_21626479 = ref object of OpenApiRestCall_21625435
proc url_DescribeProductView_21626481(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProductView_21626480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626482 = header.getOrDefault("X-Amz-Date")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Date", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Security-Token", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Target")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductView"))
  if valid_21626484 != nil:
    section.add "X-Amz-Target", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Algorithm", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Signature")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Signature", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Credential")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Credential", valid_21626489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626491: Call_DescribeProductView_21626479; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_21626491.validator(path, query, header, formData, body, _)
  let scheme = call_21626491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626491.makeUrl(scheme.get, call_21626491.host, call_21626491.base,
                               call_21626491.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626491, uri, valid, _)

proc call*(call_21626492: Call_DescribeProductView_21626479; body: JsonNode): Recallable =
  ## describeProductView
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_21626493 = newJObject()
  if body != nil:
    body_21626493 = body
  result = call_21626492.call(nil, nil, nil, nil, body_21626493)

var describeProductView* = Call_DescribeProductView_21626479(
    name: "describeProductView", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView",
    validator: validate_DescribeProductView_21626480, base: "/",
    makeUrl: url_DescribeProductView_21626481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProduct_21626494 = ref object of OpenApiRestCall_21625435
proc url_DescribeProvisionedProduct_21626496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisionedProduct_21626495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626497 = header.getOrDefault("X-Amz-Date")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Date", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Security-Token", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Target")
  valid_21626499 = validateParameter(valid_21626499, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProduct"))
  if valid_21626499 != nil:
    section.add "X-Amz-Target", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Algorithm", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Signature")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Signature", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Credential")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Credential", valid_21626504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626506: Call_DescribeProvisionedProduct_21626494;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified provisioned product.
  ## 
  let valid = call_21626506.validator(path, query, header, formData, body, _)
  let scheme = call_21626506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626506.makeUrl(scheme.get, call_21626506.host, call_21626506.base,
                               call_21626506.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626506, uri, valid, _)

proc call*(call_21626507: Call_DescribeProvisionedProduct_21626494; body: JsonNode): Recallable =
  ## describeProvisionedProduct
  ## Gets information about the specified provisioned product.
  ##   body: JObject (required)
  var body_21626508 = newJObject()
  if body != nil:
    body_21626508 = body
  result = call_21626507.call(nil, nil, nil, nil, body_21626508)

var describeProvisionedProduct* = Call_DescribeProvisionedProduct_21626494(
    name: "describeProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct",
    validator: validate_DescribeProvisionedProduct_21626495, base: "/",
    makeUrl: url_DescribeProvisionedProduct_21626496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProductPlan_21626509 = ref object of OpenApiRestCall_21625435
proc url_DescribeProvisionedProductPlan_21626511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisionedProductPlan_21626510(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626512 = header.getOrDefault("X-Amz-Date")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Date", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Security-Token", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Target")
  valid_21626514 = validateParameter(valid_21626514, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProductPlan"))
  if valid_21626514 != nil:
    section.add "X-Amz-Target", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Algorithm", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Signature")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Signature", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Credential")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Credential", valid_21626519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626521: Call_DescribeProvisionedProductPlan_21626509;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the resource changes for the specified plan.
  ## 
  let valid = call_21626521.validator(path, query, header, formData, body, _)
  let scheme = call_21626521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626521.makeUrl(scheme.get, call_21626521.host, call_21626521.base,
                               call_21626521.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626521, uri, valid, _)

proc call*(call_21626522: Call_DescribeProvisionedProductPlan_21626509;
          body: JsonNode): Recallable =
  ## describeProvisionedProductPlan
  ## Gets information about the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_21626523 = newJObject()
  if body != nil:
    body_21626523 = body
  result = call_21626522.call(nil, nil, nil, nil, body_21626523)

var describeProvisionedProductPlan* = Call_DescribeProvisionedProductPlan_21626509(
    name: "describeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan",
    validator: validate_DescribeProvisionedProductPlan_21626510, base: "/",
    makeUrl: url_DescribeProvisionedProductPlan_21626511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningArtifact_21626524 = ref object of OpenApiRestCall_21625435
proc url_DescribeProvisioningArtifact_21626526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisioningArtifact_21626525(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626527 = header.getOrDefault("X-Amz-Date")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Date", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Security-Token", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Target")
  valid_21626529 = validateParameter(valid_21626529, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningArtifact"))
  if valid_21626529 != nil:
    section.add "X-Amz-Target", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Algorithm", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Signature")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Signature", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Credential")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Credential", valid_21626534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626536: Call_DescribeProvisioningArtifact_21626524;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ## 
  let valid = call_21626536.validator(path, query, header, formData, body, _)
  let scheme = call_21626536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626536.makeUrl(scheme.get, call_21626536.host, call_21626536.base,
                               call_21626536.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626536, uri, valid, _)

proc call*(call_21626537: Call_DescribeProvisioningArtifact_21626524;
          body: JsonNode): Recallable =
  ## describeProvisioningArtifact
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ##   body: JObject (required)
  var body_21626538 = newJObject()
  if body != nil:
    body_21626538 = body
  result = call_21626537.call(nil, nil, nil, nil, body_21626538)

var describeProvisioningArtifact* = Call_DescribeProvisioningArtifact_21626524(
    name: "describeProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact",
    validator: validate_DescribeProvisioningArtifact_21626525, base: "/",
    makeUrl: url_DescribeProvisioningArtifact_21626526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningParameters_21626539 = ref object of OpenApiRestCall_21625435
proc url_DescribeProvisioningParameters_21626541(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisioningParameters_21626540(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Target")
  valid_21626544 = validateParameter(valid_21626544, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningParameters"))
  if valid_21626544 != nil:
    section.add "X-Amz-Target", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Algorithm", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Signature")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Signature", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Credential")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Credential", valid_21626549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626551: Call_DescribeProvisioningParameters_21626539;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ## 
  let valid = call_21626551.validator(path, query, header, formData, body, _)
  let scheme = call_21626551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626551.makeUrl(scheme.get, call_21626551.host, call_21626551.base,
                               call_21626551.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626551, uri, valid, _)

proc call*(call_21626552: Call_DescribeProvisioningParameters_21626539;
          body: JsonNode): Recallable =
  ## describeProvisioningParameters
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ##   body: JObject (required)
  var body_21626553 = newJObject()
  if body != nil:
    body_21626553 = body
  result = call_21626552.call(nil, nil, nil, nil, body_21626553)

var describeProvisioningParameters* = Call_DescribeProvisioningParameters_21626539(
    name: "describeProvisioningParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters",
    validator: validate_DescribeProvisioningParameters_21626540, base: "/",
    makeUrl: url_DescribeProvisioningParameters_21626541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecord_21626554 = ref object of OpenApiRestCall_21625435
proc url_DescribeRecord_21626556(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRecord_21626555(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626557 = header.getOrDefault("X-Amz-Date")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Date", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Security-Token", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Target")
  valid_21626559 = validateParameter(valid_21626559, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeRecord"))
  if valid_21626559 != nil:
    section.add "X-Amz-Target", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Algorithm", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Signature")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Signature", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Credential")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Credential", valid_21626564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626566: Call_DescribeRecord_21626554; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_DescribeRecord_21626554; body: JsonNode): Recallable =
  ## describeRecord
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ##   body: JObject (required)
  var body_21626568 = newJObject()
  if body != nil:
    body_21626568 = body
  result = call_21626567.call(nil, nil, nil, nil, body_21626568)

var describeRecord* = Call_DescribeRecord_21626554(name: "describeRecord",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord",
    validator: validate_DescribeRecord_21626555, base: "/",
    makeUrl: url_DescribeRecord_21626556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceAction_21626569 = ref object of OpenApiRestCall_21625435
proc url_DescribeServiceAction_21626571(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServiceAction_21626570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626572 = header.getOrDefault("X-Amz-Date")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Date", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Security-Token", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Target")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceAction"))
  if valid_21626574 != nil:
    section.add "X-Amz-Target", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Algorithm", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Signature")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Signature", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Credential")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Credential", valid_21626579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626581: Call_DescribeServiceAction_21626569;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a self-service action.
  ## 
  let valid = call_21626581.validator(path, query, header, formData, body, _)
  let scheme = call_21626581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626581.makeUrl(scheme.get, call_21626581.host, call_21626581.base,
                               call_21626581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626581, uri, valid, _)

proc call*(call_21626582: Call_DescribeServiceAction_21626569; body: JsonNode): Recallable =
  ## describeServiceAction
  ## Describes a self-service action.
  ##   body: JObject (required)
  var body_21626583 = newJObject()
  if body != nil:
    body_21626583 = body
  result = call_21626582.call(nil, nil, nil, nil, body_21626583)

var describeServiceAction* = Call_DescribeServiceAction_21626569(
    name: "describeServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction",
    validator: validate_DescribeServiceAction_21626570, base: "/",
    makeUrl: url_DescribeServiceAction_21626571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceActionExecutionParameters_21626584 = ref object of OpenApiRestCall_21625435
proc url_DescribeServiceActionExecutionParameters_21626586(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServiceActionExecutionParameters_21626585(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626587 = header.getOrDefault("X-Amz-Date")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Date", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Security-Token", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Target")
  valid_21626589 = validateParameter(valid_21626589, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"))
  if valid_21626589 != nil:
    section.add "X-Amz-Target", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Algorithm", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Signature")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Signature", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Credential")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Credential", valid_21626594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626596: Call_DescribeServiceActionExecutionParameters_21626584;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Finds the default parameters for a specific self-service action on a specific provisioned product and returns a map of the results to the user.
  ## 
  let valid = call_21626596.validator(path, query, header, formData, body, _)
  let scheme = call_21626596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626596.makeUrl(scheme.get, call_21626596.host, call_21626596.base,
                               call_21626596.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626596, uri, valid, _)

proc call*(call_21626597: Call_DescribeServiceActionExecutionParameters_21626584;
          body: JsonNode): Recallable =
  ## describeServiceActionExecutionParameters
  ## Finds the default parameters for a specific self-service action on a specific provisioned product and returns a map of the results to the user.
  ##   body: JObject (required)
  var body_21626598 = newJObject()
  if body != nil:
    body_21626598 = body
  result = call_21626597.call(nil, nil, nil, nil, body_21626598)

var describeServiceActionExecutionParameters* = Call_DescribeServiceActionExecutionParameters_21626584(
    name: "describeServiceActionExecutionParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters",
    validator: validate_DescribeServiceActionExecutionParameters_21626585,
    base: "/", makeUrl: url_DescribeServiceActionExecutionParameters_21626586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTagOption_21626599 = ref object of OpenApiRestCall_21625435
proc url_DescribeTagOption_21626601(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTagOption_21626600(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626602 = header.getOrDefault("X-Amz-Date")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Date", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Security-Token", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Target")
  valid_21626604 = validateParameter(valid_21626604, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeTagOption"))
  if valid_21626604 != nil:
    section.add "X-Amz-Target", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Algorithm", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-Signature")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Signature", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-Credential")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Credential", valid_21626609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626611: Call_DescribeTagOption_21626599; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified TagOption.
  ## 
  let valid = call_21626611.validator(path, query, header, formData, body, _)
  let scheme = call_21626611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626611.makeUrl(scheme.get, call_21626611.host, call_21626611.base,
                               call_21626611.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626611, uri, valid, _)

proc call*(call_21626612: Call_DescribeTagOption_21626599; body: JsonNode): Recallable =
  ## describeTagOption
  ## Gets information about the specified TagOption.
  ##   body: JObject (required)
  var body_21626613 = newJObject()
  if body != nil:
    body_21626613 = body
  result = call_21626612.call(nil, nil, nil, nil, body_21626613)

var describeTagOption* = Call_DescribeTagOption_21626599(name: "describeTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption",
    validator: validate_DescribeTagOption_21626600, base: "/",
    makeUrl: url_DescribeTagOption_21626601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSOrganizationsAccess_21626614 = ref object of OpenApiRestCall_21625435
proc url_DisableAWSOrganizationsAccess_21626616(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableAWSOrganizationsAccess_21626615(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626617 = header.getOrDefault("X-Amz-Date")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Date", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Security-Token", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Target")
  valid_21626619 = validateParameter(valid_21626619, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"))
  if valid_21626619 != nil:
    section.add "X-Amz-Target", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Algorithm", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Signature")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Signature", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-Credential")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Credential", valid_21626624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626626: Call_DisableAWSOrganizationsAccess_21626614;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ## 
  let valid = call_21626626.validator(path, query, header, formData, body, _)
  let scheme = call_21626626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626626.makeUrl(scheme.get, call_21626626.host, call_21626626.base,
                               call_21626626.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626626, uri, valid, _)

proc call*(call_21626627: Call_DisableAWSOrganizationsAccess_21626614;
          body: JsonNode): Recallable =
  ## disableAWSOrganizationsAccess
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_21626628 = newJObject()
  if body != nil:
    body_21626628 = body
  result = call_21626627.call(nil, nil, nil, nil, body_21626628)

var disableAWSOrganizationsAccess* = Call_DisableAWSOrganizationsAccess_21626614(
    name: "disableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess",
    validator: validate_DisableAWSOrganizationsAccess_21626615, base: "/",
    makeUrl: url_DisableAWSOrganizationsAccess_21626616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateBudgetFromResource_21626629 = ref object of OpenApiRestCall_21625435
proc url_DisassociateBudgetFromResource_21626631(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateBudgetFromResource_21626630(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626632 = header.getOrDefault("X-Amz-Date")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Date", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Security-Token", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Target")
  valid_21626634 = validateParameter(valid_21626634, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateBudgetFromResource"))
  if valid_21626634 != nil:
    section.add "X-Amz-Target", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-Algorithm", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Signature")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Signature", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-Credential")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Credential", valid_21626639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626641: Call_DisassociateBudgetFromResource_21626629;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified budget from the specified resource.
  ## 
  let valid = call_21626641.validator(path, query, header, formData, body, _)
  let scheme = call_21626641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626641.makeUrl(scheme.get, call_21626641.host, call_21626641.base,
                               call_21626641.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626641, uri, valid, _)

proc call*(call_21626642: Call_DisassociateBudgetFromResource_21626629;
          body: JsonNode): Recallable =
  ## disassociateBudgetFromResource
  ## Disassociates the specified budget from the specified resource.
  ##   body: JObject (required)
  var body_21626643 = newJObject()
  if body != nil:
    body_21626643 = body
  result = call_21626642.call(nil, nil, nil, nil, body_21626643)

var disassociateBudgetFromResource* = Call_DisassociateBudgetFromResource_21626629(
    name: "disassociateBudgetFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource",
    validator: validate_DisassociateBudgetFromResource_21626630, base: "/",
    makeUrl: url_DisassociateBudgetFromResource_21626631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePrincipalFromPortfolio_21626644 = ref object of OpenApiRestCall_21625435
proc url_DisassociatePrincipalFromPortfolio_21626646(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociatePrincipalFromPortfolio_21626645(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626647 = header.getOrDefault("X-Amz-Date")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Date", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Security-Token", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Target")
  valid_21626649 = validateParameter(valid_21626649, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"))
  if valid_21626649 != nil:
    section.add "X-Amz-Target", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Algorithm", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Signature")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Signature", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Credential")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Credential", valid_21626654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626656: Call_DisassociatePrincipalFromPortfolio_21626644;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ## 
  let valid = call_21626656.validator(path, query, header, formData, body, _)
  let scheme = call_21626656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626656.makeUrl(scheme.get, call_21626656.host, call_21626656.base,
                               call_21626656.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626656, uri, valid, _)

proc call*(call_21626657: Call_DisassociatePrincipalFromPortfolio_21626644;
          body: JsonNode): Recallable =
  ## disassociatePrincipalFromPortfolio
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ##   body: JObject (required)
  var body_21626658 = newJObject()
  if body != nil:
    body_21626658 = body
  result = call_21626657.call(nil, nil, nil, nil, body_21626658)

var disassociatePrincipalFromPortfolio* = Call_DisassociatePrincipalFromPortfolio_21626644(
    name: "disassociatePrincipalFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio",
    validator: validate_DisassociatePrincipalFromPortfolio_21626645, base: "/",
    makeUrl: url_DisassociatePrincipalFromPortfolio_21626646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateProductFromPortfolio_21626659 = ref object of OpenApiRestCall_21625435
proc url_DisassociateProductFromPortfolio_21626661(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateProductFromPortfolio_21626660(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626662 = header.getOrDefault("X-Amz-Date")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Date", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Security-Token", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Target")
  valid_21626664 = validateParameter(valid_21626664, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateProductFromPortfolio"))
  if valid_21626664 != nil:
    section.add "X-Amz-Target", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Algorithm", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Signature")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Signature", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Credential")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Credential", valid_21626669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626671: Call_DisassociateProductFromPortfolio_21626659;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified product from the specified portfolio. 
  ## 
  let valid = call_21626671.validator(path, query, header, formData, body, _)
  let scheme = call_21626671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626671.makeUrl(scheme.get, call_21626671.host, call_21626671.base,
                               call_21626671.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626671, uri, valid, _)

proc call*(call_21626672: Call_DisassociateProductFromPortfolio_21626659;
          body: JsonNode): Recallable =
  ## disassociateProductFromPortfolio
  ## Disassociates the specified product from the specified portfolio. 
  ##   body: JObject (required)
  var body_21626673 = newJObject()
  if body != nil:
    body_21626673 = body
  result = call_21626672.call(nil, nil, nil, nil, body_21626673)

var disassociateProductFromPortfolio* = Call_DisassociateProductFromPortfolio_21626659(
    name: "disassociateProductFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio",
    validator: validate_DisassociateProductFromPortfolio_21626660, base: "/",
    makeUrl: url_DisassociateProductFromPortfolio_21626661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceActionFromProvisioningArtifact_21626674 = ref object of OpenApiRestCall_21625435
proc url_DisassociateServiceActionFromProvisioningArtifact_21626676(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceActionFromProvisioningArtifact_21626675(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626677 = header.getOrDefault("X-Amz-Date")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Date", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Security-Token", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Target")
  valid_21626679 = validateParameter(valid_21626679, JString, required = true, default = newJString("AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"))
  if valid_21626679 != nil:
    section.add "X-Amz-Target", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Algorithm", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Signature")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Signature", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Credential")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Credential", valid_21626684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626686: Call_DisassociateServiceActionFromProvisioningArtifact_21626674;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ## 
  let valid = call_21626686.validator(path, query, header, formData, body, _)
  let scheme = call_21626686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626686.makeUrl(scheme.get, call_21626686.host, call_21626686.base,
                               call_21626686.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626686, uri, valid, _)

proc call*(call_21626687: Call_DisassociateServiceActionFromProvisioningArtifact_21626674;
          body: JsonNode): Recallable =
  ## disassociateServiceActionFromProvisioningArtifact
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_21626688 = newJObject()
  if body != nil:
    body_21626688 = body
  result = call_21626687.call(nil, nil, nil, nil, body_21626688)

var disassociateServiceActionFromProvisioningArtifact* = Call_DisassociateServiceActionFromProvisioningArtifact_21626674(
    name: "disassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact",
    validator: validate_DisassociateServiceActionFromProvisioningArtifact_21626675,
    base: "/", makeUrl: url_DisassociateServiceActionFromProvisioningArtifact_21626676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTagOptionFromResource_21626689 = ref object of OpenApiRestCall_21625435
proc url_DisassociateTagOptionFromResource_21626691(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateTagOptionFromResource_21626690(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626692 = header.getOrDefault("X-Amz-Date")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Date", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Security-Token", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Target")
  valid_21626694 = validateParameter(valid_21626694, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateTagOptionFromResource"))
  if valid_21626694 != nil:
    section.add "X-Amz-Target", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Algorithm", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Signature")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Signature", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-Credential")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Credential", valid_21626699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626701: Call_DisassociateTagOptionFromResource_21626689;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified TagOption from the specified resource.
  ## 
  let valid = call_21626701.validator(path, query, header, formData, body, _)
  let scheme = call_21626701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626701.makeUrl(scheme.get, call_21626701.host, call_21626701.base,
                               call_21626701.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626701, uri, valid, _)

proc call*(call_21626702: Call_DisassociateTagOptionFromResource_21626689;
          body: JsonNode): Recallable =
  ## disassociateTagOptionFromResource
  ## Disassociates the specified TagOption from the specified resource.
  ##   body: JObject (required)
  var body_21626703 = newJObject()
  if body != nil:
    body_21626703 = body
  result = call_21626702.call(nil, nil, nil, nil, body_21626703)

var disassociateTagOptionFromResource* = Call_DisassociateTagOptionFromResource_21626689(
    name: "disassociateTagOptionFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource",
    validator: validate_DisassociateTagOptionFromResource_21626690, base: "/",
    makeUrl: url_DisassociateTagOptionFromResource_21626691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSOrganizationsAccess_21626704 = ref object of OpenApiRestCall_21625435
proc url_EnableAWSOrganizationsAccess_21626706(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableAWSOrganizationsAccess_21626705(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626707 = header.getOrDefault("X-Amz-Date")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Date", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Security-Token", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Target")
  valid_21626709 = validateParameter(valid_21626709, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"))
  if valid_21626709 != nil:
    section.add "X-Amz-Target", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Algorithm", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Signature")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Signature", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Credential")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Credential", valid_21626714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626716: Call_EnableAWSOrganizationsAccess_21626704;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ## 
  let valid = call_21626716.validator(path, query, header, formData, body, _)
  let scheme = call_21626716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626716.makeUrl(scheme.get, call_21626716.host, call_21626716.base,
                               call_21626716.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626716, uri, valid, _)

proc call*(call_21626717: Call_EnableAWSOrganizationsAccess_21626704;
          body: JsonNode): Recallable =
  ## enableAWSOrganizationsAccess
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ##   body: JObject (required)
  var body_21626718 = newJObject()
  if body != nil:
    body_21626718 = body
  result = call_21626717.call(nil, nil, nil, nil, body_21626718)

var enableAWSOrganizationsAccess* = Call_EnableAWSOrganizationsAccess_21626704(
    name: "enableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess",
    validator: validate_EnableAWSOrganizationsAccess_21626705, base: "/",
    makeUrl: url_EnableAWSOrganizationsAccess_21626706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductPlan_21626719 = ref object of OpenApiRestCall_21625435
proc url_ExecuteProvisionedProductPlan_21626721(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteProvisionedProductPlan_21626720(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626722 = header.getOrDefault("X-Amz-Date")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Date", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Security-Token", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Target")
  valid_21626724 = validateParameter(valid_21626724, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"))
  if valid_21626724 != nil:
    section.add "X-Amz-Target", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Algorithm", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Signature")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Signature", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Credential")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Credential", valid_21626729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626731: Call_ExecuteProvisionedProductPlan_21626719;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ## 
  let valid = call_21626731.validator(path, query, header, formData, body, _)
  let scheme = call_21626731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626731.makeUrl(scheme.get, call_21626731.host, call_21626731.base,
                               call_21626731.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626731, uri, valid, _)

proc call*(call_21626732: Call_ExecuteProvisionedProductPlan_21626719;
          body: JsonNode): Recallable =
  ## executeProvisionedProductPlan
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_21626733 = newJObject()
  if body != nil:
    body_21626733 = body
  result = call_21626732.call(nil, nil, nil, nil, body_21626733)

var executeProvisionedProductPlan* = Call_ExecuteProvisionedProductPlan_21626719(
    name: "executeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan",
    validator: validate_ExecuteProvisionedProductPlan_21626720, base: "/",
    makeUrl: url_ExecuteProvisionedProductPlan_21626721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductServiceAction_21626734 = ref object of OpenApiRestCall_21625435
proc url_ExecuteProvisionedProductServiceAction_21626736(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteProvisionedProductServiceAction_21626735(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626737 = header.getOrDefault("X-Amz-Date")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Date", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Security-Token", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Target")
  valid_21626739 = validateParameter(valid_21626739, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"))
  if valid_21626739 != nil:
    section.add "X-Amz-Target", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-Algorithm", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-Signature")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Signature", valid_21626742
  var valid_21626743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Credential")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Credential", valid_21626744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626746: Call_ExecuteProvisionedProductServiceAction_21626734;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Executes a self-service action against a provisioned product.
  ## 
  let valid = call_21626746.validator(path, query, header, formData, body, _)
  let scheme = call_21626746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626746.makeUrl(scheme.get, call_21626746.host, call_21626746.base,
                               call_21626746.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626746, uri, valid, _)

proc call*(call_21626747: Call_ExecuteProvisionedProductServiceAction_21626734;
          body: JsonNode): Recallable =
  ## executeProvisionedProductServiceAction
  ## Executes a self-service action against a provisioned product.
  ##   body: JObject (required)
  var body_21626748 = newJObject()
  if body != nil:
    body_21626748 = body
  result = call_21626747.call(nil, nil, nil, nil, body_21626748)

var executeProvisionedProductServiceAction* = Call_ExecuteProvisionedProductServiceAction_21626734(
    name: "executeProvisionedProductServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction",
    validator: validate_ExecuteProvisionedProductServiceAction_21626735,
    base: "/", makeUrl: url_ExecuteProvisionedProductServiceAction_21626736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSOrganizationsAccessStatus_21626749 = ref object of OpenApiRestCall_21625435
proc url_GetAWSOrganizationsAccessStatus_21626751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAWSOrganizationsAccessStatus_21626750(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626752 = header.getOrDefault("X-Amz-Date")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Date", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Security-Token", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Target")
  valid_21626754 = validateParameter(valid_21626754, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"))
  if valid_21626754 != nil:
    section.add "X-Amz-Target", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Algorithm", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Signature")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Signature", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Credential")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Credential", valid_21626759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626761: Call_GetAWSOrganizationsAccessStatus_21626749;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ## 
  let valid = call_21626761.validator(path, query, header, formData, body, _)
  let scheme = call_21626761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626761.makeUrl(scheme.get, call_21626761.host, call_21626761.base,
                               call_21626761.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626761, uri, valid, _)

proc call*(call_21626762: Call_GetAWSOrganizationsAccessStatus_21626749;
          body: JsonNode): Recallable =
  ## getAWSOrganizationsAccessStatus
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_21626763 = newJObject()
  if body != nil:
    body_21626763 = body
  result = call_21626762.call(nil, nil, nil, nil, body_21626763)

var getAWSOrganizationsAccessStatus* = Call_GetAWSOrganizationsAccessStatus_21626749(
    name: "getAWSOrganizationsAccessStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus",
    validator: validate_GetAWSOrganizationsAccessStatus_21626750, base: "/",
    makeUrl: url_GetAWSOrganizationsAccessStatus_21626751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAcceptedPortfolioShares_21626764 = ref object of OpenApiRestCall_21625435
proc url_ListAcceptedPortfolioShares_21626766(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAcceptedPortfolioShares_21626765(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626767 = query.getOrDefault("PageSize")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "PageSize", valid_21626767
  var valid_21626768 = query.getOrDefault("PageToken")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "PageToken", valid_21626768
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
  var valid_21626769 = header.getOrDefault("X-Amz-Date")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-Date", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Security-Token", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Target")
  valid_21626771 = validateParameter(valid_21626771, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListAcceptedPortfolioShares"))
  if valid_21626771 != nil:
    section.add "X-Amz-Target", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-Algorithm", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Signature")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Signature", valid_21626774
  var valid_21626775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Credential")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Credential", valid_21626776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626778: Call_ListAcceptedPortfolioShares_21626764;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  let valid = call_21626778.validator(path, query, header, formData, body, _)
  let scheme = call_21626778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626778.makeUrl(scheme.get, call_21626778.host, call_21626778.base,
                               call_21626778.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626778, uri, valid, _)

proc call*(call_21626779: Call_ListAcceptedPortfolioShares_21626764;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listAcceptedPortfolioShares
  ## Lists all portfolios for which sharing was accepted by this account.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626781 = newJObject()
  var body_21626782 = newJObject()
  add(query_21626781, "PageSize", newJString(PageSize))
  add(query_21626781, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626782 = body
  result = call_21626779.call(nil, query_21626781, nil, nil, body_21626782)

var listAcceptedPortfolioShares* = Call_ListAcceptedPortfolioShares_21626764(
    name: "listAcceptedPortfolioShares", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares",
    validator: validate_ListAcceptedPortfolioShares_21626765, base: "/",
    makeUrl: url_ListAcceptedPortfolioShares_21626766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBudgetsForResource_21626786 = ref object of OpenApiRestCall_21625435
proc url_ListBudgetsForResource_21626788(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBudgetsForResource_21626787(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626789 = query.getOrDefault("PageSize")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "PageSize", valid_21626789
  var valid_21626790 = query.getOrDefault("PageToken")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "PageToken", valid_21626790
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
  var valid_21626791 = header.getOrDefault("X-Amz-Date")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Date", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Security-Token", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Target")
  valid_21626793 = validateParameter(valid_21626793, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListBudgetsForResource"))
  if valid_21626793 != nil:
    section.add "X-Amz-Target", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Algorithm", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Signature")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Signature", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Credential")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Credential", valid_21626798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626800: Call_ListBudgetsForResource_21626786;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the budgets associated to the specified resource.
  ## 
  let valid = call_21626800.validator(path, query, header, formData, body, _)
  let scheme = call_21626800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626800.makeUrl(scheme.get, call_21626800.host, call_21626800.base,
                               call_21626800.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626800, uri, valid, _)

proc call*(call_21626801: Call_ListBudgetsForResource_21626786; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listBudgetsForResource
  ## Lists all the budgets associated to the specified resource.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626802 = newJObject()
  var body_21626803 = newJObject()
  add(query_21626802, "PageSize", newJString(PageSize))
  add(query_21626802, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626803 = body
  result = call_21626801.call(nil, query_21626802, nil, nil, body_21626803)

var listBudgetsForResource* = Call_ListBudgetsForResource_21626786(
    name: "listBudgetsForResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource",
    validator: validate_ListBudgetsForResource_21626787, base: "/",
    makeUrl: url_ListBudgetsForResource_21626788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConstraintsForPortfolio_21626804 = ref object of OpenApiRestCall_21625435
proc url_ListConstraintsForPortfolio_21626806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConstraintsForPortfolio_21626805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626807 = query.getOrDefault("PageSize")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "PageSize", valid_21626807
  var valid_21626808 = query.getOrDefault("PageToken")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "PageToken", valid_21626808
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
  var valid_21626809 = header.getOrDefault("X-Amz-Date")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Date", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Security-Token", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-Target")
  valid_21626811 = validateParameter(valid_21626811, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListConstraintsForPortfolio"))
  if valid_21626811 != nil:
    section.add "X-Amz-Target", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Algorithm", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Signature")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Signature", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-Credential")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Credential", valid_21626816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626818: Call_ListConstraintsForPortfolio_21626804;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  let valid = call_21626818.validator(path, query, header, formData, body, _)
  let scheme = call_21626818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626818.makeUrl(scheme.get, call_21626818.host, call_21626818.base,
                               call_21626818.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626818, uri, valid, _)

proc call*(call_21626819: Call_ListConstraintsForPortfolio_21626804;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listConstraintsForPortfolio
  ## Lists the constraints for the specified portfolio and product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626820 = newJObject()
  var body_21626821 = newJObject()
  add(query_21626820, "PageSize", newJString(PageSize))
  add(query_21626820, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626821 = body
  result = call_21626819.call(nil, query_21626820, nil, nil, body_21626821)

var listConstraintsForPortfolio* = Call_ListConstraintsForPortfolio_21626804(
    name: "listConstraintsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio",
    validator: validate_ListConstraintsForPortfolio_21626805, base: "/",
    makeUrl: url_ListConstraintsForPortfolio_21626806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLaunchPaths_21626822 = ref object of OpenApiRestCall_21625435
proc url_ListLaunchPaths_21626824(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLaunchPaths_21626823(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626825 = query.getOrDefault("PageSize")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "PageSize", valid_21626825
  var valid_21626826 = query.getOrDefault("PageToken")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "PageToken", valid_21626826
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
  var valid_21626827 = header.getOrDefault("X-Amz-Date")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Date", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Security-Token", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Target")
  valid_21626829 = validateParameter(valid_21626829, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListLaunchPaths"))
  if valid_21626829 != nil:
    section.add "X-Amz-Target", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Algorithm", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Signature")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Signature", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Credential")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Credential", valid_21626834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626836: Call_ListLaunchPaths_21626822; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  let valid = call_21626836.validator(path, query, header, formData, body, _)
  let scheme = call_21626836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626836.makeUrl(scheme.get, call_21626836.host, call_21626836.base,
                               call_21626836.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626836, uri, valid, _)

proc call*(call_21626837: Call_ListLaunchPaths_21626822; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listLaunchPaths
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626838 = newJObject()
  var body_21626839 = newJObject()
  add(query_21626838, "PageSize", newJString(PageSize))
  add(query_21626838, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626839 = body
  result = call_21626837.call(nil, query_21626838, nil, nil, body_21626839)

var listLaunchPaths* = Call_ListLaunchPaths_21626822(name: "listLaunchPaths",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths",
    validator: validate_ListLaunchPaths_21626823, base: "/",
    makeUrl: url_ListLaunchPaths_21626824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationPortfolioAccess_21626840 = ref object of OpenApiRestCall_21625435
proc url_ListOrganizationPortfolioAccess_21626842(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOrganizationPortfolioAccess_21626841(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626843 = query.getOrDefault("PageSize")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "PageSize", valid_21626843
  var valid_21626844 = query.getOrDefault("PageToken")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "PageToken", valid_21626844
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
  var valid_21626845 = header.getOrDefault("X-Amz-Date")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Date", valid_21626845
  var valid_21626846 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "X-Amz-Security-Token", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-Target")
  valid_21626847 = validateParameter(valid_21626847, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"))
  if valid_21626847 != nil:
    section.add "X-Amz-Target", valid_21626847
  var valid_21626848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626848
  var valid_21626849 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "X-Amz-Algorithm", valid_21626849
  var valid_21626850 = header.getOrDefault("X-Amz-Signature")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "X-Amz-Signature", valid_21626850
  var valid_21626851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626851
  var valid_21626852 = header.getOrDefault("X-Amz-Credential")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "X-Amz-Credential", valid_21626852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626854: Call_ListOrganizationPortfolioAccess_21626840;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  let valid = call_21626854.validator(path, query, header, formData, body, _)
  let scheme = call_21626854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626854.makeUrl(scheme.get, call_21626854.host, call_21626854.base,
                               call_21626854.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626854, uri, valid, _)

proc call*(call_21626855: Call_ListOrganizationPortfolioAccess_21626840;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listOrganizationPortfolioAccess
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626856 = newJObject()
  var body_21626857 = newJObject()
  add(query_21626856, "PageSize", newJString(PageSize))
  add(query_21626856, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626857 = body
  result = call_21626855.call(nil, query_21626856, nil, nil, body_21626857)

var listOrganizationPortfolioAccess* = Call_ListOrganizationPortfolioAccess_21626840(
    name: "listOrganizationPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess",
    validator: validate_ListOrganizationPortfolioAccess_21626841, base: "/",
    makeUrl: url_ListOrganizationPortfolioAccess_21626842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolioAccess_21626858 = ref object of OpenApiRestCall_21625435
proc url_ListPortfolioAccess_21626860(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfolioAccess_21626859(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626861 = query.getOrDefault("PageSize")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "PageSize", valid_21626861
  var valid_21626862 = query.getOrDefault("PageToken")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "PageToken", valid_21626862
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
  var valid_21626863 = header.getOrDefault("X-Amz-Date")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-Date", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Security-Token", valid_21626864
  var valid_21626865 = header.getOrDefault("X-Amz-Target")
  valid_21626865 = validateParameter(valid_21626865, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolioAccess"))
  if valid_21626865 != nil:
    section.add "X-Amz-Target", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Algorithm", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Signature")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Signature", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-Credential")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Credential", valid_21626870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626872: Call_ListPortfolioAccess_21626858; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the account IDs that have access to the specified portfolio.
  ## 
  let valid = call_21626872.validator(path, query, header, formData, body, _)
  let scheme = call_21626872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626872.makeUrl(scheme.get, call_21626872.host, call_21626872.base,
                               call_21626872.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626872, uri, valid, _)

proc call*(call_21626873: Call_ListPortfolioAccess_21626858; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfolioAccess
  ## Lists the account IDs that have access to the specified portfolio.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626874 = newJObject()
  var body_21626875 = newJObject()
  add(query_21626874, "PageSize", newJString(PageSize))
  add(query_21626874, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626875 = body
  result = call_21626873.call(nil, query_21626874, nil, nil, body_21626875)

var listPortfolioAccess* = Call_ListPortfolioAccess_21626858(
    name: "listPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess",
    validator: validate_ListPortfolioAccess_21626859, base: "/",
    makeUrl: url_ListPortfolioAccess_21626860,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolios_21626876 = ref object of OpenApiRestCall_21625435
proc url_ListPortfolios_21626878(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfolios_21626877(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626879 = query.getOrDefault("PageSize")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "PageSize", valid_21626879
  var valid_21626880 = query.getOrDefault("PageToken")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "PageToken", valid_21626880
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
  var valid_21626881 = header.getOrDefault("X-Amz-Date")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "X-Amz-Date", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Security-Token", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Target")
  valid_21626883 = validateParameter(valid_21626883, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolios"))
  if valid_21626883 != nil:
    section.add "X-Amz-Target", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Algorithm", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Signature")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Signature", valid_21626886
  var valid_21626887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Credential")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Credential", valid_21626888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626890: Call_ListPortfolios_21626876; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all portfolios in the catalog.
  ## 
  let valid = call_21626890.validator(path, query, header, formData, body, _)
  let scheme = call_21626890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626890.makeUrl(scheme.get, call_21626890.host, call_21626890.base,
                               call_21626890.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626890, uri, valid, _)

proc call*(call_21626891: Call_ListPortfolios_21626876; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfolios
  ## Lists all portfolios in the catalog.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626892 = newJObject()
  var body_21626893 = newJObject()
  add(query_21626892, "PageSize", newJString(PageSize))
  add(query_21626892, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626893 = body
  result = call_21626891.call(nil, query_21626892, nil, nil, body_21626893)

var listPortfolios* = Call_ListPortfolios_21626876(name: "listPortfolios",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios",
    validator: validate_ListPortfolios_21626877, base: "/",
    makeUrl: url_ListPortfolios_21626878, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfoliosForProduct_21626894 = ref object of OpenApiRestCall_21625435
proc url_ListPortfoliosForProduct_21626896(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfoliosForProduct_21626895(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626897 = query.getOrDefault("PageSize")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "PageSize", valid_21626897
  var valid_21626898 = query.getOrDefault("PageToken")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "PageToken", valid_21626898
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
  var valid_21626899 = header.getOrDefault("X-Amz-Date")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Date", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Security-Token", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Target")
  valid_21626901 = validateParameter(valid_21626901, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfoliosForProduct"))
  if valid_21626901 != nil:
    section.add "X-Amz-Target", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Algorithm", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Signature")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-Signature", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-Credential")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-Credential", valid_21626906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626908: Call_ListPortfoliosForProduct_21626894;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  let valid = call_21626908.validator(path, query, header, formData, body, _)
  let scheme = call_21626908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626908.makeUrl(scheme.get, call_21626908.host, call_21626908.base,
                               call_21626908.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626908, uri, valid, _)

proc call*(call_21626909: Call_ListPortfoliosForProduct_21626894; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfoliosForProduct
  ## Lists all portfolios that the specified product is associated with.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626910 = newJObject()
  var body_21626911 = newJObject()
  add(query_21626910, "PageSize", newJString(PageSize))
  add(query_21626910, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626911 = body
  result = call_21626909.call(nil, query_21626910, nil, nil, body_21626911)

var listPortfoliosForProduct* = Call_ListPortfoliosForProduct_21626894(
    name: "listPortfoliosForProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct",
    validator: validate_ListPortfoliosForProduct_21626895, base: "/",
    makeUrl: url_ListPortfoliosForProduct_21626896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipalsForPortfolio_21626912 = ref object of OpenApiRestCall_21625435
proc url_ListPrincipalsForPortfolio_21626914(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPrincipalsForPortfolio_21626913(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626915 = query.getOrDefault("PageSize")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "PageSize", valid_21626915
  var valid_21626916 = query.getOrDefault("PageToken")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "PageToken", valid_21626916
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
  var valid_21626917 = header.getOrDefault("X-Amz-Date")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Date", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Security-Token", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Target")
  valid_21626919 = validateParameter(valid_21626919, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPrincipalsForPortfolio"))
  if valid_21626919 != nil:
    section.add "X-Amz-Target", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-Algorithm", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-Signature")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-Signature", valid_21626922
  var valid_21626923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626923
  var valid_21626924 = header.getOrDefault("X-Amz-Credential")
  valid_21626924 = validateParameter(valid_21626924, JString, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "X-Amz-Credential", valid_21626924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626926: Call_ListPrincipalsForPortfolio_21626912;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  let valid = call_21626926.validator(path, query, header, formData, body, _)
  let scheme = call_21626926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626926.makeUrl(scheme.get, call_21626926.host, call_21626926.base,
                               call_21626926.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626926, uri, valid, _)

proc call*(call_21626927: Call_ListPrincipalsForPortfolio_21626912; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPrincipalsForPortfolio
  ## Lists all principal ARNs associated with the specified portfolio.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626928 = newJObject()
  var body_21626929 = newJObject()
  add(query_21626928, "PageSize", newJString(PageSize))
  add(query_21626928, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626929 = body
  result = call_21626927.call(nil, query_21626928, nil, nil, body_21626929)

var listPrincipalsForPortfolio* = Call_ListPrincipalsForPortfolio_21626912(
    name: "listPrincipalsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio",
    validator: validate_ListPrincipalsForPortfolio_21626913, base: "/",
    makeUrl: url_ListPrincipalsForPortfolio_21626914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedProductPlans_21626930 = ref object of OpenApiRestCall_21625435
proc url_ListProvisionedProductPlans_21626932(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisionedProductPlans_21626931(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626933 = header.getOrDefault("X-Amz-Date")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Date", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Security-Token", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Target")
  valid_21626935 = validateParameter(valid_21626935, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisionedProductPlans"))
  if valid_21626935 != nil:
    section.add "X-Amz-Target", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Algorithm", valid_21626937
  var valid_21626938 = header.getOrDefault("X-Amz-Signature")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "X-Amz-Signature", valid_21626938
  var valid_21626939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626939 = validateParameter(valid_21626939, JString, required = false,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626939
  var valid_21626940 = header.getOrDefault("X-Amz-Credential")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "X-Amz-Credential", valid_21626940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626942: Call_ListProvisionedProductPlans_21626930;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ## 
  let valid = call_21626942.validator(path, query, header, formData, body, _)
  let scheme = call_21626942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626942.makeUrl(scheme.get, call_21626942.host, call_21626942.base,
                               call_21626942.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626942, uri, valid, _)

proc call*(call_21626943: Call_ListProvisionedProductPlans_21626930; body: JsonNode): Recallable =
  ## listProvisionedProductPlans
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ##   body: JObject (required)
  var body_21626944 = newJObject()
  if body != nil:
    body_21626944 = body
  result = call_21626943.call(nil, nil, nil, nil, body_21626944)

var listProvisionedProductPlans* = Call_ListProvisionedProductPlans_21626930(
    name: "listProvisionedProductPlans", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans",
    validator: validate_ListProvisionedProductPlans_21626931, base: "/",
    makeUrl: url_ListProvisionedProductPlans_21626932,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifacts_21626945 = ref object of OpenApiRestCall_21625435
proc url_ListProvisioningArtifacts_21626947(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisioningArtifacts_21626946(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626948 = header.getOrDefault("X-Amz-Date")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Date", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Security-Token", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Target")
  valid_21626950 = validateParameter(valid_21626950, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifacts"))
  if valid_21626950 != nil:
    section.add "X-Amz-Target", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Algorithm", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-Signature")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-Signature", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626954
  var valid_21626955 = header.getOrDefault("X-Amz-Credential")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-Credential", valid_21626955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626957: Call_ListProvisioningArtifacts_21626945;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ## 
  let valid = call_21626957.validator(path, query, header, formData, body, _)
  let scheme = call_21626957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626957.makeUrl(scheme.get, call_21626957.host, call_21626957.base,
                               call_21626957.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626957, uri, valid, _)

proc call*(call_21626958: Call_ListProvisioningArtifacts_21626945; body: JsonNode): Recallable =
  ## listProvisioningArtifacts
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ##   body: JObject (required)
  var body_21626959 = newJObject()
  if body != nil:
    body_21626959 = body
  result = call_21626958.call(nil, nil, nil, nil, body_21626959)

var listProvisioningArtifacts* = Call_ListProvisioningArtifacts_21626945(
    name: "listProvisioningArtifacts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts",
    validator: validate_ListProvisioningArtifacts_21626946, base: "/",
    makeUrl: url_ListProvisioningArtifacts_21626947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifactsForServiceAction_21626960 = ref object of OpenApiRestCall_21625435
proc url_ListProvisioningArtifactsForServiceAction_21626962(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisioningArtifactsForServiceAction_21626961(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626963 = query.getOrDefault("PageSize")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "PageSize", valid_21626963
  var valid_21626964 = query.getOrDefault("PageToken")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "PageToken", valid_21626964
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
  var valid_21626965 = header.getOrDefault("X-Amz-Date")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Date", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Security-Token", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Target")
  valid_21626967 = validateParameter(valid_21626967, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"))
  if valid_21626967 != nil:
    section.add "X-Amz-Target", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Algorithm", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-Signature")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Signature", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626971
  var valid_21626972 = header.getOrDefault("X-Amz-Credential")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-Credential", valid_21626972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626974: Call_ListProvisioningArtifactsForServiceAction_21626960;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  let valid = call_21626974.validator(path, query, header, formData, body, _)
  let scheme = call_21626974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626974.makeUrl(scheme.get, call_21626974.host, call_21626974.base,
                               call_21626974.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626974, uri, valid, _)

proc call*(call_21626975: Call_ListProvisioningArtifactsForServiceAction_21626960;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listProvisioningArtifactsForServiceAction
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626976 = newJObject()
  var body_21626977 = newJObject()
  add(query_21626976, "PageSize", newJString(PageSize))
  add(query_21626976, "PageToken", newJString(PageToken))
  if body != nil:
    body_21626977 = body
  result = call_21626975.call(nil, query_21626976, nil, nil, body_21626977)

var listProvisioningArtifactsForServiceAction* = Call_ListProvisioningArtifactsForServiceAction_21626960(
    name: "listProvisioningArtifactsForServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction",
    validator: validate_ListProvisioningArtifactsForServiceAction_21626961,
    base: "/", makeUrl: url_ListProvisioningArtifactsForServiceAction_21626962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecordHistory_21626978 = ref object of OpenApiRestCall_21625435
proc url_ListRecordHistory_21626980(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRecordHistory_21626979(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626981 = header.getOrDefault("X-Amz-Date")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Date", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Security-Token", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-Target")
  valid_21626983 = validateParameter(valid_21626983, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListRecordHistory"))
  if valid_21626983 != nil:
    section.add "X-Amz-Target", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Algorithm", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-Signature")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-Signature", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-Credential")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Credential", valid_21626988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626990: Call_ListRecordHistory_21626978; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the specified requests or all performed requests.
  ## 
  let valid = call_21626990.validator(path, query, header, formData, body, _)
  let scheme = call_21626990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626990.makeUrl(scheme.get, call_21626990.host, call_21626990.base,
                               call_21626990.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626990, uri, valid, _)

proc call*(call_21626991: Call_ListRecordHistory_21626978; body: JsonNode): Recallable =
  ## listRecordHistory
  ## Lists the specified requests or all performed requests.
  ##   body: JObject (required)
  var body_21626992 = newJObject()
  if body != nil:
    body_21626992 = body
  result = call_21626991.call(nil, nil, nil, nil, body_21626992)

var listRecordHistory* = Call_ListRecordHistory_21626978(name: "listRecordHistory",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory",
    validator: validate_ListRecordHistory_21626979, base: "/",
    makeUrl: url_ListRecordHistory_21626980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForTagOption_21626993 = ref object of OpenApiRestCall_21625435
proc url_ListResourcesForTagOption_21626995(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourcesForTagOption_21626994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626996 = query.getOrDefault("PageSize")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "PageSize", valid_21626996
  var valid_21626997 = query.getOrDefault("PageToken")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "PageToken", valid_21626997
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
  var valid_21626998 = header.getOrDefault("X-Amz-Date")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Date", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Security-Token", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Target")
  valid_21627000 = validateParameter(valid_21627000, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListResourcesForTagOption"))
  if valid_21627000 != nil:
    section.add "X-Amz-Target", valid_21627000
  var valid_21627001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627001 = validateParameter(valid_21627001, JString, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627001
  var valid_21627002 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-Algorithm", valid_21627002
  var valid_21627003 = header.getOrDefault("X-Amz-Signature")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "X-Amz-Signature", valid_21627003
  var valid_21627004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627004
  var valid_21627005 = header.getOrDefault("X-Amz-Credential")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "X-Amz-Credential", valid_21627005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627007: Call_ListResourcesForTagOption_21626993;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resources associated with the specified TagOption.
  ## 
  let valid = call_21627007.validator(path, query, header, formData, body, _)
  let scheme = call_21627007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627007.makeUrl(scheme.get, call_21627007.host, call_21627007.base,
                               call_21627007.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627007, uri, valid, _)

proc call*(call_21627008: Call_ListResourcesForTagOption_21626993; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listResourcesForTagOption
  ## Lists the resources associated with the specified TagOption.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21627009 = newJObject()
  var body_21627010 = newJObject()
  add(query_21627009, "PageSize", newJString(PageSize))
  add(query_21627009, "PageToken", newJString(PageToken))
  if body != nil:
    body_21627010 = body
  result = call_21627008.call(nil, query_21627009, nil, nil, body_21627010)

var listResourcesForTagOption* = Call_ListResourcesForTagOption_21626993(
    name: "listResourcesForTagOption", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption",
    validator: validate_ListResourcesForTagOption_21626994, base: "/",
    makeUrl: url_ListResourcesForTagOption_21626995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActions_21627011 = ref object of OpenApiRestCall_21625435
proc url_ListServiceActions_21627013(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceActions_21627012(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627014 = query.getOrDefault("PageSize")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "PageSize", valid_21627014
  var valid_21627015 = query.getOrDefault("PageToken")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "PageToken", valid_21627015
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
  var valid_21627016 = header.getOrDefault("X-Amz-Date")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "X-Amz-Date", valid_21627016
  var valid_21627017 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "X-Amz-Security-Token", valid_21627017
  var valid_21627018 = header.getOrDefault("X-Amz-Target")
  valid_21627018 = validateParameter(valid_21627018, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActions"))
  if valid_21627018 != nil:
    section.add "X-Amz-Target", valid_21627018
  var valid_21627019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Algorithm", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Signature")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Signature", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-Credential")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Credential", valid_21627023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627025: Call_ListServiceActions_21627011; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all self-service actions.
  ## 
  let valid = call_21627025.validator(path, query, header, formData, body, _)
  let scheme = call_21627025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627025.makeUrl(scheme.get, call_21627025.host, call_21627025.base,
                               call_21627025.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627025, uri, valid, _)

proc call*(call_21627026: Call_ListServiceActions_21627011; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActions
  ## Lists all self-service actions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21627027 = newJObject()
  var body_21627028 = newJObject()
  add(query_21627027, "PageSize", newJString(PageSize))
  add(query_21627027, "PageToken", newJString(PageToken))
  if body != nil:
    body_21627028 = body
  result = call_21627026.call(nil, query_21627027, nil, nil, body_21627028)

var listServiceActions* = Call_ListServiceActions_21627011(
    name: "listServiceActions", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions",
    validator: validate_ListServiceActions_21627012, base: "/",
    makeUrl: url_ListServiceActions_21627013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActionsForProvisioningArtifact_21627029 = ref object of OpenApiRestCall_21625435
proc url_ListServiceActionsForProvisioningArtifact_21627031(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceActionsForProvisioningArtifact_21627030(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627032 = query.getOrDefault("PageSize")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "PageSize", valid_21627032
  var valid_21627033 = query.getOrDefault("PageToken")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "PageToken", valid_21627033
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
  var valid_21627034 = header.getOrDefault("X-Amz-Date")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Date", valid_21627034
  var valid_21627035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627035 = validateParameter(valid_21627035, JString, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "X-Amz-Security-Token", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-Target")
  valid_21627036 = validateParameter(valid_21627036, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"))
  if valid_21627036 != nil:
    section.add "X-Amz-Target", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Algorithm", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Signature")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Signature", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-Credential")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Credential", valid_21627041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627043: Call_ListServiceActionsForProvisioningArtifact_21627029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  let valid = call_21627043.validator(path, query, header, formData, body, _)
  let scheme = call_21627043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627043.makeUrl(scheme.get, call_21627043.host, call_21627043.base,
                               call_21627043.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627043, uri, valid, _)

proc call*(call_21627044: Call_ListServiceActionsForProvisioningArtifact_21627029;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActionsForProvisioningArtifact
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21627045 = newJObject()
  var body_21627046 = newJObject()
  add(query_21627045, "PageSize", newJString(PageSize))
  add(query_21627045, "PageToken", newJString(PageToken))
  if body != nil:
    body_21627046 = body
  result = call_21627044.call(nil, query_21627045, nil, nil, body_21627046)

var listServiceActionsForProvisioningArtifact* = Call_ListServiceActionsForProvisioningArtifact_21627029(
    name: "listServiceActionsForProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact",
    validator: validate_ListServiceActionsForProvisioningArtifact_21627030,
    base: "/", makeUrl: url_ListServiceActionsForProvisioningArtifact_21627031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStackInstancesForProvisionedProduct_21627047 = ref object of OpenApiRestCall_21625435
proc url_ListStackInstancesForProvisionedProduct_21627049(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStackInstancesForProvisionedProduct_21627048(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627050 = header.getOrDefault("X-Amz-Date")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "X-Amz-Date", valid_21627050
  var valid_21627051 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627051 = validateParameter(valid_21627051, JString, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "X-Amz-Security-Token", valid_21627051
  var valid_21627052 = header.getOrDefault("X-Amz-Target")
  valid_21627052 = validateParameter(valid_21627052, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"))
  if valid_21627052 != nil:
    section.add "X-Amz-Target", valid_21627052
  var valid_21627053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "X-Amz-Algorithm", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Signature")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Signature", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Credential")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Credential", valid_21627057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627059: Call_ListStackInstancesForProvisionedProduct_21627047;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ## 
  let valid = call_21627059.validator(path, query, header, formData, body, _)
  let scheme = call_21627059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627059.makeUrl(scheme.get, call_21627059.host, call_21627059.base,
                               call_21627059.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627059, uri, valid, _)

proc call*(call_21627060: Call_ListStackInstancesForProvisionedProduct_21627047;
          body: JsonNode): Recallable =
  ## listStackInstancesForProvisionedProduct
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ##   body: JObject (required)
  var body_21627061 = newJObject()
  if body != nil:
    body_21627061 = body
  result = call_21627060.call(nil, nil, nil, nil, body_21627061)

var listStackInstancesForProvisionedProduct* = Call_ListStackInstancesForProvisionedProduct_21627047(
    name: "listStackInstancesForProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct",
    validator: validate_ListStackInstancesForProvisionedProduct_21627048,
    base: "/", makeUrl: url_ListStackInstancesForProvisionedProduct_21627049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagOptions_21627062 = ref object of OpenApiRestCall_21625435
proc url_ListTagOptions_21627064(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagOptions_21627063(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627065 = query.getOrDefault("PageSize")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "PageSize", valid_21627065
  var valid_21627066 = query.getOrDefault("PageToken")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "PageToken", valid_21627066
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
  var valid_21627067 = header.getOrDefault("X-Amz-Date")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Date", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Security-Token", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Target")
  valid_21627069 = validateParameter(valid_21627069, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListTagOptions"))
  if valid_21627069 != nil:
    section.add "X-Amz-Target", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Algorithm", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Signature")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Signature", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Credential")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Credential", valid_21627074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627076: Call_ListTagOptions_21627062; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  let valid = call_21627076.validator(path, query, header, formData, body, _)
  let scheme = call_21627076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627076.makeUrl(scheme.get, call_21627076.host, call_21627076.base,
                               call_21627076.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627076, uri, valid, _)

proc call*(call_21627077: Call_ListTagOptions_21627062; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listTagOptions
  ## Lists the specified TagOptions or all TagOptions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21627078 = newJObject()
  var body_21627079 = newJObject()
  add(query_21627078, "PageSize", newJString(PageSize))
  add(query_21627078, "PageToken", newJString(PageToken))
  if body != nil:
    body_21627079 = body
  result = call_21627077.call(nil, query_21627078, nil, nil, body_21627079)

var listTagOptions* = Call_ListTagOptions_21627062(name: "listTagOptions",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions",
    validator: validate_ListTagOptions_21627063, base: "/",
    makeUrl: url_ListTagOptions_21627064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ProvisionProduct_21627080 = ref object of OpenApiRestCall_21625435
proc url_ProvisionProduct_21627082(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ProvisionProduct_21627081(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627083 = header.getOrDefault("X-Amz-Date")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Date", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-Security-Token", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Target")
  valid_21627085 = validateParameter(valid_21627085, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ProvisionProduct"))
  if valid_21627085 != nil:
    section.add "X-Amz-Target", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Algorithm", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-Signature")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-Signature", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627089
  var valid_21627090 = header.getOrDefault("X-Amz-Credential")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Credential", valid_21627090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627092: Call_ProvisionProduct_21627080; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ## 
  let valid = call_21627092.validator(path, query, header, formData, body, _)
  let scheme = call_21627092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627092.makeUrl(scheme.get, call_21627092.host, call_21627092.base,
                               call_21627092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627092, uri, valid, _)

proc call*(call_21627093: Call_ProvisionProduct_21627080; body: JsonNode): Recallable =
  ## provisionProduct
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ##   body: JObject (required)
  var body_21627094 = newJObject()
  if body != nil:
    body_21627094 = body
  result = call_21627093.call(nil, nil, nil, nil, body_21627094)

var provisionProduct* = Call_ProvisionProduct_21627080(name: "provisionProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct",
    validator: validate_ProvisionProduct_21627081, base: "/",
    makeUrl: url_ProvisionProduct_21627082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectPortfolioShare_21627095 = ref object of OpenApiRestCall_21625435
proc url_RejectPortfolioShare_21627097(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectPortfolioShare_21627096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627098 = header.getOrDefault("X-Amz-Date")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Date", valid_21627098
  var valid_21627099 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "X-Amz-Security-Token", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Target")
  valid_21627100 = validateParameter(valid_21627100, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.RejectPortfolioShare"))
  if valid_21627100 != nil:
    section.add "X-Amz-Target", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Algorithm", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-Signature")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-Signature", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Credential")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Credential", valid_21627105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627107: Call_RejectPortfolioShare_21627095; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Rejects an offer to share the specified portfolio.
  ## 
  let valid = call_21627107.validator(path, query, header, formData, body, _)
  let scheme = call_21627107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627107.makeUrl(scheme.get, call_21627107.host, call_21627107.base,
                               call_21627107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627107, uri, valid, _)

proc call*(call_21627108: Call_RejectPortfolioShare_21627095; body: JsonNode): Recallable =
  ## rejectPortfolioShare
  ## Rejects an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_21627109 = newJObject()
  if body != nil:
    body_21627109 = body
  result = call_21627108.call(nil, nil, nil, nil, body_21627109)

var rejectPortfolioShare* = Call_RejectPortfolioShare_21627095(
    name: "rejectPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare",
    validator: validate_RejectPortfolioShare_21627096, base: "/",
    makeUrl: url_RejectPortfolioShare_21627097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScanProvisionedProducts_21627110 = ref object of OpenApiRestCall_21625435
proc url_ScanProvisionedProducts_21627112(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ScanProvisionedProducts_21627111(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627113 = header.getOrDefault("X-Amz-Date")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "X-Amz-Date", valid_21627113
  var valid_21627114 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627114 = validateParameter(valid_21627114, JString, required = false,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "X-Amz-Security-Token", valid_21627114
  var valid_21627115 = header.getOrDefault("X-Amz-Target")
  valid_21627115 = validateParameter(valid_21627115, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ScanProvisionedProducts"))
  if valid_21627115 != nil:
    section.add "X-Amz-Target", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Algorithm", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Signature")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-Signature", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-Credential")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-Credential", valid_21627120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627122: Call_ScanProvisionedProducts_21627110;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ## 
  let valid = call_21627122.validator(path, query, header, formData, body, _)
  let scheme = call_21627122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627122.makeUrl(scheme.get, call_21627122.host, call_21627122.base,
                               call_21627122.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627122, uri, valid, _)

proc call*(call_21627123: Call_ScanProvisionedProducts_21627110; body: JsonNode): Recallable =
  ## scanProvisionedProducts
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ##   body: JObject (required)
  var body_21627124 = newJObject()
  if body != nil:
    body_21627124 = body
  result = call_21627123.call(nil, nil, nil, nil, body_21627124)

var scanProvisionedProducts* = Call_ScanProvisionedProducts_21627110(
    name: "scanProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts",
    validator: validate_ScanProvisionedProducts_21627111, base: "/",
    makeUrl: url_ScanProvisionedProducts_21627112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProducts_21627125 = ref object of OpenApiRestCall_21625435
proc url_SearchProducts_21627127(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProducts_21627126(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627128 = query.getOrDefault("PageSize")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "PageSize", valid_21627128
  var valid_21627129 = query.getOrDefault("PageToken")
  valid_21627129 = validateParameter(valid_21627129, JString, required = false,
                                   default = nil)
  if valid_21627129 != nil:
    section.add "PageToken", valid_21627129
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
  var valid_21627130 = header.getOrDefault("X-Amz-Date")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Date", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Security-Token", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Target")
  valid_21627132 = validateParameter(valid_21627132, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProducts"))
  if valid_21627132 != nil:
    section.add "X-Amz-Target", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Algorithm", valid_21627134
  var valid_21627135 = header.getOrDefault("X-Amz-Signature")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-Signature", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627136
  var valid_21627137 = header.getOrDefault("X-Amz-Credential")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "X-Amz-Credential", valid_21627137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627139: Call_SearchProducts_21627125; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the products to which the caller has access.
  ## 
  let valid = call_21627139.validator(path, query, header, formData, body, _)
  let scheme = call_21627139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627139.makeUrl(scheme.get, call_21627139.host, call_21627139.base,
                               call_21627139.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627139, uri, valid, _)

proc call*(call_21627140: Call_SearchProducts_21627125; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProducts
  ## Gets information about the products to which the caller has access.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21627141 = newJObject()
  var body_21627142 = newJObject()
  add(query_21627141, "PageSize", newJString(PageSize))
  add(query_21627141, "PageToken", newJString(PageToken))
  if body != nil:
    body_21627142 = body
  result = call_21627140.call(nil, query_21627141, nil, nil, body_21627142)

var searchProducts* = Call_SearchProducts_21627125(name: "searchProducts",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts",
    validator: validate_SearchProducts_21627126, base: "/",
    makeUrl: url_SearchProducts_21627127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProductsAsAdmin_21627143 = ref object of OpenApiRestCall_21625435
proc url_SearchProductsAsAdmin_21627145(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProductsAsAdmin_21627144(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627146 = query.getOrDefault("PageSize")
  valid_21627146 = validateParameter(valid_21627146, JString, required = false,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "PageSize", valid_21627146
  var valid_21627147 = query.getOrDefault("PageToken")
  valid_21627147 = validateParameter(valid_21627147, JString, required = false,
                                   default = nil)
  if valid_21627147 != nil:
    section.add "PageToken", valid_21627147
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
  var valid_21627148 = header.getOrDefault("X-Amz-Date")
  valid_21627148 = validateParameter(valid_21627148, JString, required = false,
                                   default = nil)
  if valid_21627148 != nil:
    section.add "X-Amz-Date", valid_21627148
  var valid_21627149 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627149 = validateParameter(valid_21627149, JString, required = false,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "X-Amz-Security-Token", valid_21627149
  var valid_21627150 = header.getOrDefault("X-Amz-Target")
  valid_21627150 = validateParameter(valid_21627150, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProductsAsAdmin"))
  if valid_21627150 != nil:
    section.add "X-Amz-Target", valid_21627150
  var valid_21627151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627151 = validateParameter(valid_21627151, JString, required = false,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627151
  var valid_21627152 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Algorithm", valid_21627152
  var valid_21627153 = header.getOrDefault("X-Amz-Signature")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Signature", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Credential")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Credential", valid_21627155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627157: Call_SearchProductsAsAdmin_21627143;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  let valid = call_21627157.validator(path, query, header, formData, body, _)
  let scheme = call_21627157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627157.makeUrl(scheme.get, call_21627157.host, call_21627157.base,
                               call_21627157.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627157, uri, valid, _)

proc call*(call_21627158: Call_SearchProductsAsAdmin_21627143; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProductsAsAdmin
  ## Gets information about the products for the specified portfolio or all products.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21627159 = newJObject()
  var body_21627160 = newJObject()
  add(query_21627159, "PageSize", newJString(PageSize))
  add(query_21627159, "PageToken", newJString(PageToken))
  if body != nil:
    body_21627160 = body
  result = call_21627158.call(nil, query_21627159, nil, nil, body_21627160)

var searchProductsAsAdmin* = Call_SearchProductsAsAdmin_21627143(
    name: "searchProductsAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin",
    validator: validate_SearchProductsAsAdmin_21627144, base: "/",
    makeUrl: url_SearchProductsAsAdmin_21627145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProvisionedProducts_21627161 = ref object of OpenApiRestCall_21625435
proc url_SearchProvisionedProducts_21627163(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProvisionedProducts_21627162(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627164 = query.getOrDefault("PageSize")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "PageSize", valid_21627164
  var valid_21627165 = query.getOrDefault("PageToken")
  valid_21627165 = validateParameter(valid_21627165, JString, required = false,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "PageToken", valid_21627165
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
  var valid_21627166 = header.getOrDefault("X-Amz-Date")
  valid_21627166 = validateParameter(valid_21627166, JString, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "X-Amz-Date", valid_21627166
  var valid_21627167 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "X-Amz-Security-Token", valid_21627167
  var valid_21627168 = header.getOrDefault("X-Amz-Target")
  valid_21627168 = validateParameter(valid_21627168, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProvisionedProducts"))
  if valid_21627168 != nil:
    section.add "X-Amz-Target", valid_21627168
  var valid_21627169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "X-Amz-Algorithm", valid_21627170
  var valid_21627171 = header.getOrDefault("X-Amz-Signature")
  valid_21627171 = validateParameter(valid_21627171, JString, required = false,
                                   default = nil)
  if valid_21627171 != nil:
    section.add "X-Amz-Signature", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-Credential")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Credential", valid_21627173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627175: Call_SearchProvisionedProducts_21627161;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  let valid = call_21627175.validator(path, query, header, formData, body, _)
  let scheme = call_21627175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627175.makeUrl(scheme.get, call_21627175.host, call_21627175.base,
                               call_21627175.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627175, uri, valid, _)

proc call*(call_21627176: Call_SearchProvisionedProducts_21627161; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProvisionedProducts
  ## Gets information about the provisioned products that meet the specified criteria.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21627177 = newJObject()
  var body_21627178 = newJObject()
  add(query_21627177, "PageSize", newJString(PageSize))
  add(query_21627177, "PageToken", newJString(PageToken))
  if body != nil:
    body_21627178 = body
  result = call_21627176.call(nil, query_21627177, nil, nil, body_21627178)

var searchProvisionedProducts* = Call_SearchProvisionedProducts_21627161(
    name: "searchProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts",
    validator: validate_SearchProvisionedProducts_21627162, base: "/",
    makeUrl: url_SearchProvisionedProducts_21627163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateProvisionedProduct_21627179 = ref object of OpenApiRestCall_21625435
proc url_TerminateProvisionedProduct_21627181(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateProvisionedProduct_21627180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627182 = header.getOrDefault("X-Amz-Date")
  valid_21627182 = validateParameter(valid_21627182, JString, required = false,
                                   default = nil)
  if valid_21627182 != nil:
    section.add "X-Amz-Date", valid_21627182
  var valid_21627183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627183 = validateParameter(valid_21627183, JString, required = false,
                                   default = nil)
  if valid_21627183 != nil:
    section.add "X-Amz-Security-Token", valid_21627183
  var valid_21627184 = header.getOrDefault("X-Amz-Target")
  valid_21627184 = validateParameter(valid_21627184, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.TerminateProvisionedProduct"))
  if valid_21627184 != nil:
    section.add "X-Amz-Target", valid_21627184
  var valid_21627185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627185 = validateParameter(valid_21627185, JString, required = false,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627185
  var valid_21627186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Algorithm", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-Signature")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Signature", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Credential")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-Credential", valid_21627189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627191: Call_TerminateProvisionedProduct_21627179;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_21627191.validator(path, query, header, formData, body, _)
  let scheme = call_21627191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627191.makeUrl(scheme.get, call_21627191.host, call_21627191.base,
                               call_21627191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627191, uri, valid, _)

proc call*(call_21627192: Call_TerminateProvisionedProduct_21627179; body: JsonNode): Recallable =
  ## terminateProvisionedProduct
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_21627193 = newJObject()
  if body != nil:
    body_21627193 = body
  result = call_21627192.call(nil, nil, nil, nil, body_21627193)

var terminateProvisionedProduct* = Call_TerminateProvisionedProduct_21627179(
    name: "terminateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct",
    validator: validate_TerminateProvisionedProduct_21627180, base: "/",
    makeUrl: url_TerminateProvisionedProduct_21627181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConstraint_21627194 = ref object of OpenApiRestCall_21625435
proc url_UpdateConstraint_21627196(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConstraint_21627195(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627197 = header.getOrDefault("X-Amz-Date")
  valid_21627197 = validateParameter(valid_21627197, JString, required = false,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "X-Amz-Date", valid_21627197
  var valid_21627198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627198 = validateParameter(valid_21627198, JString, required = false,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "X-Amz-Security-Token", valid_21627198
  var valid_21627199 = header.getOrDefault("X-Amz-Target")
  valid_21627199 = validateParameter(valid_21627199, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateConstraint"))
  if valid_21627199 != nil:
    section.add "X-Amz-Target", valid_21627199
  var valid_21627200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627200 = validateParameter(valid_21627200, JString, required = false,
                                   default = nil)
  if valid_21627200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627200
  var valid_21627201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627201 = validateParameter(valid_21627201, JString, required = false,
                                   default = nil)
  if valid_21627201 != nil:
    section.add "X-Amz-Algorithm", valid_21627201
  var valid_21627202 = header.getOrDefault("X-Amz-Signature")
  valid_21627202 = validateParameter(valid_21627202, JString, required = false,
                                   default = nil)
  if valid_21627202 != nil:
    section.add "X-Amz-Signature", valid_21627202
  var valid_21627203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Credential")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-Credential", valid_21627204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627206: Call_UpdateConstraint_21627194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified constraint.
  ## 
  let valid = call_21627206.validator(path, query, header, formData, body, _)
  let scheme = call_21627206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627206.makeUrl(scheme.get, call_21627206.host, call_21627206.base,
                               call_21627206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627206, uri, valid, _)

proc call*(call_21627207: Call_UpdateConstraint_21627194; body: JsonNode): Recallable =
  ## updateConstraint
  ## Updates the specified constraint.
  ##   body: JObject (required)
  var body_21627208 = newJObject()
  if body != nil:
    body_21627208 = body
  result = call_21627207.call(nil, nil, nil, nil, body_21627208)

var updateConstraint* = Call_UpdateConstraint_21627194(name: "updateConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint",
    validator: validate_UpdateConstraint_21627195, base: "/",
    makeUrl: url_UpdateConstraint_21627196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePortfolio_21627209 = ref object of OpenApiRestCall_21625435
proc url_UpdatePortfolio_21627211(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePortfolio_21627210(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627212 = header.getOrDefault("X-Amz-Date")
  valid_21627212 = validateParameter(valid_21627212, JString, required = false,
                                   default = nil)
  if valid_21627212 != nil:
    section.add "X-Amz-Date", valid_21627212
  var valid_21627213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627213 = validateParameter(valid_21627213, JString, required = false,
                                   default = nil)
  if valid_21627213 != nil:
    section.add "X-Amz-Security-Token", valid_21627213
  var valid_21627214 = header.getOrDefault("X-Amz-Target")
  valid_21627214 = validateParameter(valid_21627214, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdatePortfolio"))
  if valid_21627214 != nil:
    section.add "X-Amz-Target", valid_21627214
  var valid_21627215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627215 = validateParameter(valid_21627215, JString, required = false,
                                   default = nil)
  if valid_21627215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627215
  var valid_21627216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627216 = validateParameter(valid_21627216, JString, required = false,
                                   default = nil)
  if valid_21627216 != nil:
    section.add "X-Amz-Algorithm", valid_21627216
  var valid_21627217 = header.getOrDefault("X-Amz-Signature")
  valid_21627217 = validateParameter(valid_21627217, JString, required = false,
                                   default = nil)
  if valid_21627217 != nil:
    section.add "X-Amz-Signature", valid_21627217
  var valid_21627218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Credential")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Credential", valid_21627219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627221: Call_UpdatePortfolio_21627209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ## 
  let valid = call_21627221.validator(path, query, header, formData, body, _)
  let scheme = call_21627221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627221.makeUrl(scheme.get, call_21627221.host, call_21627221.base,
                               call_21627221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627221, uri, valid, _)

proc call*(call_21627222: Call_UpdatePortfolio_21627209; body: JsonNode): Recallable =
  ## updatePortfolio
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_21627223 = newJObject()
  if body != nil:
    body_21627223 = body
  result = call_21627222.call(nil, nil, nil, nil, body_21627223)

var updatePortfolio* = Call_UpdatePortfolio_21627209(name: "updatePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio",
    validator: validate_UpdatePortfolio_21627210, base: "/",
    makeUrl: url_UpdatePortfolio_21627211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProduct_21627224 = ref object of OpenApiRestCall_21625435
proc url_UpdateProduct_21627226(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProduct_21627225(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627227 = header.getOrDefault("X-Amz-Date")
  valid_21627227 = validateParameter(valid_21627227, JString, required = false,
                                   default = nil)
  if valid_21627227 != nil:
    section.add "X-Amz-Date", valid_21627227
  var valid_21627228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627228 = validateParameter(valid_21627228, JString, required = false,
                                   default = nil)
  if valid_21627228 != nil:
    section.add "X-Amz-Security-Token", valid_21627228
  var valid_21627229 = header.getOrDefault("X-Amz-Target")
  valid_21627229 = validateParameter(valid_21627229, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProduct"))
  if valid_21627229 != nil:
    section.add "X-Amz-Target", valid_21627229
  var valid_21627230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627230 = validateParameter(valid_21627230, JString, required = false,
                                   default = nil)
  if valid_21627230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627230
  var valid_21627231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627231 = validateParameter(valid_21627231, JString, required = false,
                                   default = nil)
  if valid_21627231 != nil:
    section.add "X-Amz-Algorithm", valid_21627231
  var valid_21627232 = header.getOrDefault("X-Amz-Signature")
  valid_21627232 = validateParameter(valid_21627232, JString, required = false,
                                   default = nil)
  if valid_21627232 != nil:
    section.add "X-Amz-Signature", valid_21627232
  var valid_21627233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627233
  var valid_21627234 = header.getOrDefault("X-Amz-Credential")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "X-Amz-Credential", valid_21627234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627236: Call_UpdateProduct_21627224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified product.
  ## 
  let valid = call_21627236.validator(path, query, header, formData, body, _)
  let scheme = call_21627236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627236.makeUrl(scheme.get, call_21627236.host, call_21627236.base,
                               call_21627236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627236, uri, valid, _)

proc call*(call_21627237: Call_UpdateProduct_21627224; body: JsonNode): Recallable =
  ## updateProduct
  ## Updates the specified product.
  ##   body: JObject (required)
  var body_21627238 = newJObject()
  if body != nil:
    body_21627238 = body
  result = call_21627237.call(nil, nil, nil, nil, body_21627238)

var updateProduct* = Call_UpdateProduct_21627224(name: "updateProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct",
    validator: validate_UpdateProduct_21627225, base: "/",
    makeUrl: url_UpdateProduct_21627226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProduct_21627239 = ref object of OpenApiRestCall_21625435
proc url_UpdateProvisionedProduct_21627241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisionedProduct_21627240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627242 = header.getOrDefault("X-Amz-Date")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-Date", valid_21627242
  var valid_21627243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627243 = validateParameter(valid_21627243, JString, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "X-Amz-Security-Token", valid_21627243
  var valid_21627244 = header.getOrDefault("X-Amz-Target")
  valid_21627244 = validateParameter(valid_21627244, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProduct"))
  if valid_21627244 != nil:
    section.add "X-Amz-Target", valid_21627244
  var valid_21627245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627245 = validateParameter(valid_21627245, JString, required = false,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627245
  var valid_21627246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627246 = validateParameter(valid_21627246, JString, required = false,
                                   default = nil)
  if valid_21627246 != nil:
    section.add "X-Amz-Algorithm", valid_21627246
  var valid_21627247 = header.getOrDefault("X-Amz-Signature")
  valid_21627247 = validateParameter(valid_21627247, JString, required = false,
                                   default = nil)
  if valid_21627247 != nil:
    section.add "X-Amz-Signature", valid_21627247
  var valid_21627248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627248 = validateParameter(valid_21627248, JString, required = false,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627248
  var valid_21627249 = header.getOrDefault("X-Amz-Credential")
  valid_21627249 = validateParameter(valid_21627249, JString, required = false,
                                   default = nil)
  if valid_21627249 != nil:
    section.add "X-Amz-Credential", valid_21627249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627251: Call_UpdateProvisionedProduct_21627239;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_21627251.validator(path, query, header, formData, body, _)
  let scheme = call_21627251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627251.makeUrl(scheme.get, call_21627251.host, call_21627251.base,
                               call_21627251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627251, uri, valid, _)

proc call*(call_21627252: Call_UpdateProvisionedProduct_21627239; body: JsonNode): Recallable =
  ## updateProvisionedProduct
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_21627253 = newJObject()
  if body != nil:
    body_21627253 = body
  result = call_21627252.call(nil, nil, nil, nil, body_21627253)

var updateProvisionedProduct* = Call_UpdateProvisionedProduct_21627239(
    name: "updateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct",
    validator: validate_UpdateProvisionedProduct_21627240, base: "/",
    makeUrl: url_UpdateProvisionedProduct_21627241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProductProperties_21627254 = ref object of OpenApiRestCall_21625435
proc url_UpdateProvisionedProductProperties_21627256(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisionedProductProperties_21627255(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627257 = header.getOrDefault("X-Amz-Date")
  valid_21627257 = validateParameter(valid_21627257, JString, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "X-Amz-Date", valid_21627257
  var valid_21627258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627258 = validateParameter(valid_21627258, JString, required = false,
                                   default = nil)
  if valid_21627258 != nil:
    section.add "X-Amz-Security-Token", valid_21627258
  var valid_21627259 = header.getOrDefault("X-Amz-Target")
  valid_21627259 = validateParameter(valid_21627259, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProductProperties"))
  if valid_21627259 != nil:
    section.add "X-Amz-Target", valid_21627259
  var valid_21627260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627260 = validateParameter(valid_21627260, JString, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627260
  var valid_21627261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627261 = validateParameter(valid_21627261, JString, required = false,
                                   default = nil)
  if valid_21627261 != nil:
    section.add "X-Amz-Algorithm", valid_21627261
  var valid_21627262 = header.getOrDefault("X-Amz-Signature")
  valid_21627262 = validateParameter(valid_21627262, JString, required = false,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "X-Amz-Signature", valid_21627262
  var valid_21627263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627263
  var valid_21627264 = header.getOrDefault("X-Amz-Credential")
  valid_21627264 = validateParameter(valid_21627264, JString, required = false,
                                   default = nil)
  if valid_21627264 != nil:
    section.add "X-Amz-Credential", valid_21627264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627266: Call_UpdateProvisionedProductProperties_21627254;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Requests updates to the properties of the specified provisioned product.
  ## 
  let valid = call_21627266.validator(path, query, header, formData, body, _)
  let scheme = call_21627266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627266.makeUrl(scheme.get, call_21627266.host, call_21627266.base,
                               call_21627266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627266, uri, valid, _)

proc call*(call_21627267: Call_UpdateProvisionedProductProperties_21627254;
          body: JsonNode): Recallable =
  ## updateProvisionedProductProperties
  ## Requests updates to the properties of the specified provisioned product.
  ##   body: JObject (required)
  var body_21627268 = newJObject()
  if body != nil:
    body_21627268 = body
  result = call_21627267.call(nil, nil, nil, nil, body_21627268)

var updateProvisionedProductProperties* = Call_UpdateProvisionedProductProperties_21627254(
    name: "updateProvisionedProductProperties", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties",
    validator: validate_UpdateProvisionedProductProperties_21627255, base: "/",
    makeUrl: url_UpdateProvisionedProductProperties_21627256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisioningArtifact_21627269 = ref object of OpenApiRestCall_21625435
proc url_UpdateProvisioningArtifact_21627271(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisioningArtifact_21627270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627272 = header.getOrDefault("X-Amz-Date")
  valid_21627272 = validateParameter(valid_21627272, JString, required = false,
                                   default = nil)
  if valid_21627272 != nil:
    section.add "X-Amz-Date", valid_21627272
  var valid_21627273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627273 = validateParameter(valid_21627273, JString, required = false,
                                   default = nil)
  if valid_21627273 != nil:
    section.add "X-Amz-Security-Token", valid_21627273
  var valid_21627274 = header.getOrDefault("X-Amz-Target")
  valid_21627274 = validateParameter(valid_21627274, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisioningArtifact"))
  if valid_21627274 != nil:
    section.add "X-Amz-Target", valid_21627274
  var valid_21627275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627275 = validateParameter(valid_21627275, JString, required = false,
                                   default = nil)
  if valid_21627275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627275
  var valid_21627276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-Algorithm", valid_21627276
  var valid_21627277 = header.getOrDefault("X-Amz-Signature")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-Signature", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627278
  var valid_21627279 = header.getOrDefault("X-Amz-Credential")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "X-Amz-Credential", valid_21627279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627281: Call_UpdateProvisioningArtifact_21627269;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_21627281.validator(path, query, header, formData, body, _)
  let scheme = call_21627281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627281.makeUrl(scheme.get, call_21627281.host, call_21627281.base,
                               call_21627281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627281, uri, valid, _)

proc call*(call_21627282: Call_UpdateProvisioningArtifact_21627269; body: JsonNode): Recallable =
  ## updateProvisioningArtifact
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_21627283 = newJObject()
  if body != nil:
    body_21627283 = body
  result = call_21627282.call(nil, nil, nil, nil, body_21627283)

var updateProvisioningArtifact* = Call_UpdateProvisioningArtifact_21627269(
    name: "updateProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact",
    validator: validate_UpdateProvisioningArtifact_21627270, base: "/",
    makeUrl: url_UpdateProvisioningArtifact_21627271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceAction_21627284 = ref object of OpenApiRestCall_21625435
proc url_UpdateServiceAction_21627286(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServiceAction_21627285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627287 = header.getOrDefault("X-Amz-Date")
  valid_21627287 = validateParameter(valid_21627287, JString, required = false,
                                   default = nil)
  if valid_21627287 != nil:
    section.add "X-Amz-Date", valid_21627287
  var valid_21627288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627288 = validateParameter(valid_21627288, JString, required = false,
                                   default = nil)
  if valid_21627288 != nil:
    section.add "X-Amz-Security-Token", valid_21627288
  var valid_21627289 = header.getOrDefault("X-Amz-Target")
  valid_21627289 = validateParameter(valid_21627289, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateServiceAction"))
  if valid_21627289 != nil:
    section.add "X-Amz-Target", valid_21627289
  var valid_21627290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627290 = validateParameter(valid_21627290, JString, required = false,
                                   default = nil)
  if valid_21627290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627290
  var valid_21627291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627291 = validateParameter(valid_21627291, JString, required = false,
                                   default = nil)
  if valid_21627291 != nil:
    section.add "X-Amz-Algorithm", valid_21627291
  var valid_21627292 = header.getOrDefault("X-Amz-Signature")
  valid_21627292 = validateParameter(valid_21627292, JString, required = false,
                                   default = nil)
  if valid_21627292 != nil:
    section.add "X-Amz-Signature", valid_21627292
  var valid_21627293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627293
  var valid_21627294 = header.getOrDefault("X-Amz-Credential")
  valid_21627294 = validateParameter(valid_21627294, JString, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "X-Amz-Credential", valid_21627294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627296: Call_UpdateServiceAction_21627284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a self-service action.
  ## 
  let valid = call_21627296.validator(path, query, header, formData, body, _)
  let scheme = call_21627296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627296.makeUrl(scheme.get, call_21627296.host, call_21627296.base,
                               call_21627296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627296, uri, valid, _)

proc call*(call_21627297: Call_UpdateServiceAction_21627284; body: JsonNode): Recallable =
  ## updateServiceAction
  ## Updates a self-service action.
  ##   body: JObject (required)
  var body_21627298 = newJObject()
  if body != nil:
    body_21627298 = body
  result = call_21627297.call(nil, nil, nil, nil, body_21627298)

var updateServiceAction* = Call_UpdateServiceAction_21627284(
    name: "updateServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction",
    validator: validate_UpdateServiceAction_21627285, base: "/",
    makeUrl: url_UpdateServiceAction_21627286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagOption_21627299 = ref object of OpenApiRestCall_21625435
proc url_UpdateTagOption_21627301(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTagOption_21627300(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627302 = header.getOrDefault("X-Amz-Date")
  valid_21627302 = validateParameter(valid_21627302, JString, required = false,
                                   default = nil)
  if valid_21627302 != nil:
    section.add "X-Amz-Date", valid_21627302
  var valid_21627303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627303 = validateParameter(valid_21627303, JString, required = false,
                                   default = nil)
  if valid_21627303 != nil:
    section.add "X-Amz-Security-Token", valid_21627303
  var valid_21627304 = header.getOrDefault("X-Amz-Target")
  valid_21627304 = validateParameter(valid_21627304, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateTagOption"))
  if valid_21627304 != nil:
    section.add "X-Amz-Target", valid_21627304
  var valid_21627305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627305
  var valid_21627306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "X-Amz-Algorithm", valid_21627306
  var valid_21627307 = header.getOrDefault("X-Amz-Signature")
  valid_21627307 = validateParameter(valid_21627307, JString, required = false,
                                   default = nil)
  if valid_21627307 != nil:
    section.add "X-Amz-Signature", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-Credential")
  valid_21627309 = validateParameter(valid_21627309, JString, required = false,
                                   default = nil)
  if valid_21627309 != nil:
    section.add "X-Amz-Credential", valid_21627309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627311: Call_UpdateTagOption_21627299; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified TagOption.
  ## 
  let valid = call_21627311.validator(path, query, header, formData, body, _)
  let scheme = call_21627311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627311.makeUrl(scheme.get, call_21627311.host, call_21627311.base,
                               call_21627311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627311, uri, valid, _)

proc call*(call_21627312: Call_UpdateTagOption_21627299; body: JsonNode): Recallable =
  ## updateTagOption
  ## Updates the specified TagOption.
  ##   body: JObject (required)
  var body_21627313 = newJObject()
  if body != nil:
    body_21627313 = body
  result = call_21627312.call(nil, nil, nil, nil, body_21627313)

var updateTagOption* = Call_UpdateTagOption_21627299(name: "updateTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption",
    validator: validate_UpdateTagOption_21627300, base: "/",
    makeUrl: url_UpdateTagOption_21627301, schemes: {Scheme.Https, Scheme.Http})
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}