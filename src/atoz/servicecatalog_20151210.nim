
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_AcceptPortfolioShare_599705 = ref object of OpenApiRestCall_599368
proc url_AcceptPortfolioShare_599707(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptPortfolioShare_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AcceptPortfolioShare"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_AcceptPortfolioShare_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an offer to share the specified portfolio.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AcceptPortfolioShare_599705; body: JsonNode): Recallable =
  ## acceptPortfolioShare
  ## Accepts an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var acceptPortfolioShare* = Call_AcceptPortfolioShare_599705(
    name: "acceptPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare",
    validator: validate_AcceptPortfolioShare_599706, base: "/",
    url: url_AcceptPortfolioShare_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateBudgetWithResource_599974 = ref object of OpenApiRestCall_599368
proc url_AssociateBudgetWithResource_599976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateBudgetWithResource_599975(path: JsonNode; query: JsonNode;
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
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateBudgetWithResource"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_AssociateBudgetWithResource_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified budget with the specified resource.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_AssociateBudgetWithResource_599974; body: JsonNode): Recallable =
  ## associateBudgetWithResource
  ## Associates the specified budget with the specified resource.
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var associateBudgetWithResource* = Call_AssociateBudgetWithResource_599974(
    name: "associateBudgetWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource",
    validator: validate_AssociateBudgetWithResource_599975, base: "/",
    url: url_AssociateBudgetWithResource_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePrincipalWithPortfolio_599989 = ref object of OpenApiRestCall_599368
proc url_AssociatePrincipalWithPortfolio_599991(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociatePrincipalWithPortfolio_599990(path: JsonNode;
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_AssociatePrincipalWithPortfolio_599989;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified principal ARN with the specified portfolio.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_AssociatePrincipalWithPortfolio_599989; body: JsonNode): Recallable =
  ## associatePrincipalWithPortfolio
  ## Associates the specified principal ARN with the specified portfolio.
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var associatePrincipalWithPortfolio* = Call_AssociatePrincipalWithPortfolio_599989(
    name: "associatePrincipalWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio",
    validator: validate_AssociatePrincipalWithPortfolio_599990, base: "/",
    url: url_AssociatePrincipalWithPortfolio_599991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateProductWithPortfolio_600004 = ref object of OpenApiRestCall_599368
proc url_AssociateProductWithPortfolio_600006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateProductWithPortfolio_600005(path: JsonNode; query: JsonNode;
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
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateProductWithPortfolio"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_AssociateProductWithPortfolio_600004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified product with the specified portfolio.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_AssociateProductWithPortfolio_600004; body: JsonNode): Recallable =
  ## associateProductWithPortfolio
  ## Associates the specified product with the specified portfolio.
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var associateProductWithPortfolio* = Call_AssociateProductWithPortfolio_600004(
    name: "associateProductWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio",
    validator: validate_AssociateProductWithPortfolio_600005, base: "/",
    url: url_AssociateProductWithPortfolio_600006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceActionWithProvisioningArtifact_600019 = ref object of OpenApiRestCall_599368
proc url_AssociateServiceActionWithProvisioningArtifact_600021(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceActionWithProvisioningArtifact_600020(
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
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString("AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_AssociateServiceActionWithProvisioningArtifact_600019;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a self-service action with a provisioning artifact.
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_AssociateServiceActionWithProvisioningArtifact_600019;
          body: JsonNode): Recallable =
  ## associateServiceActionWithProvisioningArtifact
  ## Associates a self-service action with a provisioning artifact.
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var associateServiceActionWithProvisioningArtifact* = Call_AssociateServiceActionWithProvisioningArtifact_600019(
    name: "associateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact",
    validator: validate_AssociateServiceActionWithProvisioningArtifact_600020,
    base: "/", url: url_AssociateServiceActionWithProvisioningArtifact_600021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTagOptionWithResource_600034 = ref object of OpenApiRestCall_599368
proc url_AssociateTagOptionWithResource_600036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateTagOptionWithResource_600035(path: JsonNode;
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateTagOptionWithResource"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_AssociateTagOptionWithResource_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associate the specified TagOption with the specified portfolio or product.
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_AssociateTagOptionWithResource_600034; body: JsonNode): Recallable =
  ## associateTagOptionWithResource
  ## Associate the specified TagOption with the specified portfolio or product.
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var associateTagOptionWithResource* = Call_AssociateTagOptionWithResource_600034(
    name: "associateTagOptionWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource",
    validator: validate_AssociateTagOptionWithResource_600035, base: "/",
    url: url_AssociateTagOptionWithResource_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateServiceActionWithProvisioningArtifact_600049 = ref object of OpenApiRestCall_599368
proc url_BatchAssociateServiceActionWithProvisioningArtifact_600051(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchAssociateServiceActionWithProvisioningArtifact_600050(
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_BatchAssociateServiceActionWithProvisioningArtifact_600049;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates multiple self-service actions with provisioning artifacts.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_BatchAssociateServiceActionWithProvisioningArtifact_600049;
          body: JsonNode): Recallable =
  ## batchAssociateServiceActionWithProvisioningArtifact
  ## Associates multiple self-service actions with provisioning artifacts.
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var batchAssociateServiceActionWithProvisioningArtifact* = Call_BatchAssociateServiceActionWithProvisioningArtifact_600049(
    name: "batchAssociateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact",
    validator: validate_BatchAssociateServiceActionWithProvisioningArtifact_600050,
    base: "/", url: url_BatchAssociateServiceActionWithProvisioningArtifact_600051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateServiceActionFromProvisioningArtifact_600064 = ref object of OpenApiRestCall_599368
proc url_BatchDisassociateServiceActionFromProvisioningArtifact_600066(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisassociateServiceActionFromProvisioningArtifact_600065(
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_BatchDisassociateServiceActionFromProvisioningArtifact_600064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_BatchDisassociateServiceActionFromProvisioningArtifact_600064;
          body: JsonNode): Recallable =
  ## batchDisassociateServiceActionFromProvisioningArtifact
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var batchDisassociateServiceActionFromProvisioningArtifact* = Call_BatchDisassociateServiceActionFromProvisioningArtifact_600064(
    name: "batchDisassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact",
    validator: validate_BatchDisassociateServiceActionFromProvisioningArtifact_600065,
    base: "/", url: url_BatchDisassociateServiceActionFromProvisioningArtifact_600066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyProduct_600079 = ref object of OpenApiRestCall_599368
proc url_CopyProduct_600081(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CopyProduct_600080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CopyProduct"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_CopyProduct_600079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_CopyProduct_600079; body: JsonNode): Recallable =
  ## copyProduct
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var copyProduct* = Call_CopyProduct_600079(name: "copyProduct",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct",
                                        validator: validate_CopyProduct_600080,
                                        base: "/", url: url_CopyProduct_600081,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConstraint_600094 = ref object of OpenApiRestCall_599368
proc url_CreateConstraint_600096(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConstraint_600095(path: JsonNode; query: JsonNode;
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
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateConstraint"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_CreateConstraint_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a constraint.
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_CreateConstraint_600094; body: JsonNode): Recallable =
  ## createConstraint
  ## Creates a constraint.
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var createConstraint* = Call_CreateConstraint_600094(name: "createConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint",
    validator: validate_CreateConstraint_600095, base: "/",
    url: url_CreateConstraint_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolio_600109 = ref object of OpenApiRestCall_599368
proc url_CreatePortfolio_600111(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePortfolio_600110(path: JsonNode; query: JsonNode;
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
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolio"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_CreatePortfolio_600109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a portfolio.
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_CreatePortfolio_600109; body: JsonNode): Recallable =
  ## createPortfolio
  ## Creates a portfolio.
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var createPortfolio* = Call_CreatePortfolio_600109(name: "createPortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio",
    validator: validate_CreatePortfolio_600110, base: "/", url: url_CreatePortfolio_600111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolioShare_600124 = ref object of OpenApiRestCall_599368
proc url_CreatePortfolioShare_600126(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePortfolioShare_600125(path: JsonNode; query: JsonNode;
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolioShare"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_CreatePortfolioShare_600124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_CreatePortfolioShare_600124; body: JsonNode): Recallable =
  ## createPortfolioShare
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var createPortfolioShare* = Call_CreatePortfolioShare_600124(
    name: "createPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare",
    validator: validate_CreatePortfolioShare_600125, base: "/",
    url: url_CreatePortfolioShare_600126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProduct_600139 = ref object of OpenApiRestCall_599368
proc url_CreateProduct_600141(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProduct_600140(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProduct"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_CreateProduct_600139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a product.
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_CreateProduct_600139; body: JsonNode): Recallable =
  ## createProduct
  ## Creates a product.
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var createProduct* = Call_CreateProduct_600139(name: "createProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct",
    validator: validate_CreateProduct_600140, base: "/", url: url_CreateProduct_600141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisionedProductPlan_600154 = ref object of OpenApiRestCall_599368
proc url_CreateProvisionedProductPlan_600156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProvisionedProductPlan_600155(path: JsonNode; query: JsonNode;
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisionedProductPlan"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_CreateProvisionedProductPlan_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_CreateProvisionedProductPlan_600154; body: JsonNode): Recallable =
  ## createProvisionedProductPlan
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var createProvisionedProductPlan* = Call_CreateProvisionedProductPlan_600154(
    name: "createProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan",
    validator: validate_CreateProvisionedProductPlan_600155, base: "/",
    url: url_CreateProvisionedProductPlan_600156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisioningArtifact_600169 = ref object of OpenApiRestCall_599368
proc url_CreateProvisioningArtifact_600171(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProvisioningArtifact_600170(path: JsonNode; query: JsonNode;
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
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisioningArtifact"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_CreateProvisioningArtifact_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_CreateProvisioningArtifact_600169; body: JsonNode): Recallable =
  ## createProvisioningArtifact
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var createProvisioningArtifact* = Call_CreateProvisioningArtifact_600169(
    name: "createProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact",
    validator: validate_CreateProvisioningArtifact_600170, base: "/",
    url: url_CreateProvisioningArtifact_600171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServiceAction_600184 = ref object of OpenApiRestCall_599368
proc url_CreateServiceAction_600186(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateServiceAction_600185(path: JsonNode; query: JsonNode;
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
  var valid_600187 = header.getOrDefault("X-Amz-Date")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Date", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Security-Token")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Security-Token", valid_600188
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600189 = header.getOrDefault("X-Amz-Target")
  valid_600189 = validateParameter(valid_600189, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateServiceAction"))
  if valid_600189 != nil:
    section.add "X-Amz-Target", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Content-Sha256", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Algorithm")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Algorithm", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Signature")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Signature", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-SignedHeaders", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Credential")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Credential", valid_600194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600196: Call_CreateServiceAction_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a self-service action.
  ## 
  let valid = call_600196.validator(path, query, header, formData, body)
  let scheme = call_600196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600196.url(scheme.get, call_600196.host, call_600196.base,
                         call_600196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600196, url, valid)

proc call*(call_600197: Call_CreateServiceAction_600184; body: JsonNode): Recallable =
  ## createServiceAction
  ## Creates a self-service action.
  ##   body: JObject (required)
  var body_600198 = newJObject()
  if body != nil:
    body_600198 = body
  result = call_600197.call(nil, nil, nil, nil, body_600198)

var createServiceAction* = Call_CreateServiceAction_600184(
    name: "createServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction",
    validator: validate_CreateServiceAction_600185, base: "/",
    url: url_CreateServiceAction_600186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTagOption_600199 = ref object of OpenApiRestCall_599368
proc url_CreateTagOption_600201(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTagOption_600200(path: JsonNode; query: JsonNode;
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
  var valid_600202 = header.getOrDefault("X-Amz-Date")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Date", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Security-Token")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Security-Token", valid_600203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600204 = header.getOrDefault("X-Amz-Target")
  valid_600204 = validateParameter(valid_600204, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateTagOption"))
  if valid_600204 != nil:
    section.add "X-Amz-Target", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600211: Call_CreateTagOption_600199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a TagOption.
  ## 
  let valid = call_600211.validator(path, query, header, formData, body)
  let scheme = call_600211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600211.url(scheme.get, call_600211.host, call_600211.base,
                         call_600211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600211, url, valid)

proc call*(call_600212: Call_CreateTagOption_600199; body: JsonNode): Recallable =
  ## createTagOption
  ## Creates a TagOption.
  ##   body: JObject (required)
  var body_600213 = newJObject()
  if body != nil:
    body_600213 = body
  result = call_600212.call(nil, nil, nil, nil, body_600213)

var createTagOption* = Call_CreateTagOption_600199(name: "createTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption",
    validator: validate_CreateTagOption_600200, base: "/", url: url_CreateTagOption_600201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConstraint_600214 = ref object of OpenApiRestCall_599368
proc url_DeleteConstraint_600216(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConstraint_600215(path: JsonNode; query: JsonNode;
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
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600219 = header.getOrDefault("X-Amz-Target")
  valid_600219 = validateParameter(valid_600219, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteConstraint"))
  if valid_600219 != nil:
    section.add "X-Amz-Target", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Content-Sha256", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Algorithm")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Algorithm", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Signature")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Signature", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-SignedHeaders", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Credential")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Credential", valid_600224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600226: Call_DeleteConstraint_600214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified constraint.
  ## 
  let valid = call_600226.validator(path, query, header, formData, body)
  let scheme = call_600226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600226.url(scheme.get, call_600226.host, call_600226.base,
                         call_600226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600226, url, valid)

proc call*(call_600227: Call_DeleteConstraint_600214; body: JsonNode): Recallable =
  ## deleteConstraint
  ## Deletes the specified constraint.
  ##   body: JObject (required)
  var body_600228 = newJObject()
  if body != nil:
    body_600228 = body
  result = call_600227.call(nil, nil, nil, nil, body_600228)

var deleteConstraint* = Call_DeleteConstraint_600214(name: "deleteConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint",
    validator: validate_DeleteConstraint_600215, base: "/",
    url: url_DeleteConstraint_600216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolio_600229 = ref object of OpenApiRestCall_599368
proc url_DeletePortfolio_600231(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePortfolio_600230(path: JsonNode; query: JsonNode;
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
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600234 = header.getOrDefault("X-Amz-Target")
  valid_600234 = validateParameter(valid_600234, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolio"))
  if valid_600234 != nil:
    section.add "X-Amz-Target", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Content-Sha256", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Algorithm")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Algorithm", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Signature")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Signature", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-SignedHeaders", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Credential")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Credential", valid_600239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600241: Call_DeletePortfolio_600229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ## 
  let valid = call_600241.validator(path, query, header, formData, body)
  let scheme = call_600241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600241.url(scheme.get, call_600241.host, call_600241.base,
                         call_600241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600241, url, valid)

proc call*(call_600242: Call_DeletePortfolio_600229; body: JsonNode): Recallable =
  ## deletePortfolio
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ##   body: JObject (required)
  var body_600243 = newJObject()
  if body != nil:
    body_600243 = body
  result = call_600242.call(nil, nil, nil, nil, body_600243)

var deletePortfolio* = Call_DeletePortfolio_600229(name: "deletePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio",
    validator: validate_DeletePortfolio_600230, base: "/", url: url_DeletePortfolio_600231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolioShare_600244 = ref object of OpenApiRestCall_599368
proc url_DeletePortfolioShare_600246(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePortfolioShare_600245(path: JsonNode; query: JsonNode;
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
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600249 = header.getOrDefault("X-Amz-Target")
  valid_600249 = validateParameter(valid_600249, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolioShare"))
  if valid_600249 != nil:
    section.add "X-Amz-Target", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Content-Sha256", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Algorithm")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Algorithm", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Signature")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Signature", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-SignedHeaders", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Credential")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Credential", valid_600254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600256: Call_DeletePortfolioShare_600244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ## 
  let valid = call_600256.validator(path, query, header, formData, body)
  let scheme = call_600256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600256.url(scheme.get, call_600256.host, call_600256.base,
                         call_600256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600256, url, valid)

proc call*(call_600257: Call_DeletePortfolioShare_600244; body: JsonNode): Recallable =
  ## deletePortfolioShare
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ##   body: JObject (required)
  var body_600258 = newJObject()
  if body != nil:
    body_600258 = body
  result = call_600257.call(nil, nil, nil, nil, body_600258)

var deletePortfolioShare* = Call_DeletePortfolioShare_600244(
    name: "deletePortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare",
    validator: validate_DeletePortfolioShare_600245, base: "/",
    url: url_DeletePortfolioShare_600246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProduct_600259 = ref object of OpenApiRestCall_599368
proc url_DeleteProduct_600261(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProduct_600260(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600262 = header.getOrDefault("X-Amz-Date")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Date", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Security-Token")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Security-Token", valid_600263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600264 = header.getOrDefault("X-Amz-Target")
  valid_600264 = validateParameter(valid_600264, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProduct"))
  if valid_600264 != nil:
    section.add "X-Amz-Target", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Content-Sha256", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Algorithm")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Algorithm", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Signature")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Signature", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-SignedHeaders", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Credential")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Credential", valid_600269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600271: Call_DeleteProduct_600259; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ## 
  let valid = call_600271.validator(path, query, header, formData, body)
  let scheme = call_600271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600271.url(scheme.get, call_600271.host, call_600271.base,
                         call_600271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600271, url, valid)

proc call*(call_600272: Call_DeleteProduct_600259; body: JsonNode): Recallable =
  ## deleteProduct
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ##   body: JObject (required)
  var body_600273 = newJObject()
  if body != nil:
    body_600273 = body
  result = call_600272.call(nil, nil, nil, nil, body_600273)

var deleteProduct* = Call_DeleteProduct_600259(name: "deleteProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct",
    validator: validate_DeleteProduct_600260, base: "/", url: url_DeleteProduct_600261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedProductPlan_600274 = ref object of OpenApiRestCall_599368
proc url_DeleteProvisionedProductPlan_600276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProvisionedProductPlan_600275(path: JsonNode; query: JsonNode;
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
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600279 = header.getOrDefault("X-Amz-Target")
  valid_600279 = validateParameter(valid_600279, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisionedProductPlan"))
  if valid_600279 != nil:
    section.add "X-Amz-Target", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_DeleteProvisionedProductPlan_600274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified plan.
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_DeleteProvisionedProductPlan_600274; body: JsonNode): Recallable =
  ## deleteProvisionedProductPlan
  ## Deletes the specified plan.
  ##   body: JObject (required)
  var body_600288 = newJObject()
  if body != nil:
    body_600288 = body
  result = call_600287.call(nil, nil, nil, nil, body_600288)

var deleteProvisionedProductPlan* = Call_DeleteProvisionedProductPlan_600274(
    name: "deleteProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan",
    validator: validate_DeleteProvisionedProductPlan_600275, base: "/",
    url: url_DeleteProvisionedProductPlan_600276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisioningArtifact_600289 = ref object of OpenApiRestCall_599368
proc url_DeleteProvisioningArtifact_600291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProvisioningArtifact_600290(path: JsonNode; query: JsonNode;
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
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600294 = header.getOrDefault("X-Amz-Target")
  valid_600294 = validateParameter(valid_600294, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisioningArtifact"))
  if valid_600294 != nil:
    section.add "X-Amz-Target", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600301: Call_DeleteProvisioningArtifact_600289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ## 
  let valid = call_600301.validator(path, query, header, formData, body)
  let scheme = call_600301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600301.url(scheme.get, call_600301.host, call_600301.base,
                         call_600301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600301, url, valid)

proc call*(call_600302: Call_DeleteProvisioningArtifact_600289; body: JsonNode): Recallable =
  ## deleteProvisioningArtifact
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ##   body: JObject (required)
  var body_600303 = newJObject()
  if body != nil:
    body_600303 = body
  result = call_600302.call(nil, nil, nil, nil, body_600303)

var deleteProvisioningArtifact* = Call_DeleteProvisioningArtifact_600289(
    name: "deleteProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact",
    validator: validate_DeleteProvisioningArtifact_600290, base: "/",
    url: url_DeleteProvisioningArtifact_600291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceAction_600304 = ref object of OpenApiRestCall_599368
proc url_DeleteServiceAction_600306(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServiceAction_600305(path: JsonNode; query: JsonNode;
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
  var valid_600307 = header.getOrDefault("X-Amz-Date")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Date", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Security-Token")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Security-Token", valid_600308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600309 = header.getOrDefault("X-Amz-Target")
  valid_600309 = validateParameter(valid_600309, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteServiceAction"))
  if valid_600309 != nil:
    section.add "X-Amz-Target", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Content-Sha256", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Algorithm")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Algorithm", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Signature")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Signature", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-SignedHeaders", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Credential")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Credential", valid_600314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_DeleteServiceAction_600304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a self-service action.
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_DeleteServiceAction_600304; body: JsonNode): Recallable =
  ## deleteServiceAction
  ## Deletes a self-service action.
  ##   body: JObject (required)
  var body_600318 = newJObject()
  if body != nil:
    body_600318 = body
  result = call_600317.call(nil, nil, nil, nil, body_600318)

var deleteServiceAction* = Call_DeleteServiceAction_600304(
    name: "deleteServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction",
    validator: validate_DeleteServiceAction_600305, base: "/",
    url: url_DeleteServiceAction_600306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagOption_600319 = ref object of OpenApiRestCall_599368
proc url_DeleteTagOption_600321(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTagOption_600320(path: JsonNode; query: JsonNode;
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
  var valid_600322 = header.getOrDefault("X-Amz-Date")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Date", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Security-Token")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Security-Token", valid_600323
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600324 = header.getOrDefault("X-Amz-Target")
  valid_600324 = validateParameter(valid_600324, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteTagOption"))
  if valid_600324 != nil:
    section.add "X-Amz-Target", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Content-Sha256", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Algorithm")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Algorithm", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Signature")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Signature", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-SignedHeaders", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Credential")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Credential", valid_600329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600331: Call_DeleteTagOption_600319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ## 
  let valid = call_600331.validator(path, query, header, formData, body)
  let scheme = call_600331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600331.url(scheme.get, call_600331.host, call_600331.base,
                         call_600331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600331, url, valid)

proc call*(call_600332: Call_DeleteTagOption_600319; body: JsonNode): Recallable =
  ## deleteTagOption
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ##   body: JObject (required)
  var body_600333 = newJObject()
  if body != nil:
    body_600333 = body
  result = call_600332.call(nil, nil, nil, nil, body_600333)

var deleteTagOption* = Call_DeleteTagOption_600319(name: "deleteTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption",
    validator: validate_DeleteTagOption_600320, base: "/", url: url_DeleteTagOption_600321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConstraint_600334 = ref object of OpenApiRestCall_599368
proc url_DescribeConstraint_600336(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConstraint_600335(path: JsonNode; query: JsonNode;
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
  var valid_600337 = header.getOrDefault("X-Amz-Date")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Date", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Security-Token")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Security-Token", valid_600338
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600339 = header.getOrDefault("X-Amz-Target")
  valid_600339 = validateParameter(valid_600339, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeConstraint"))
  if valid_600339 != nil:
    section.add "X-Amz-Target", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Content-Sha256", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Algorithm")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Algorithm", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Signature")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Signature", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-SignedHeaders", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Credential")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Credential", valid_600344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600346: Call_DescribeConstraint_600334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified constraint.
  ## 
  let valid = call_600346.validator(path, query, header, formData, body)
  let scheme = call_600346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600346.url(scheme.get, call_600346.host, call_600346.base,
                         call_600346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600346, url, valid)

proc call*(call_600347: Call_DescribeConstraint_600334; body: JsonNode): Recallable =
  ## describeConstraint
  ## Gets information about the specified constraint.
  ##   body: JObject (required)
  var body_600348 = newJObject()
  if body != nil:
    body_600348 = body
  result = call_600347.call(nil, nil, nil, nil, body_600348)

var describeConstraint* = Call_DescribeConstraint_600334(
    name: "describeConstraint", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint",
    validator: validate_DescribeConstraint_600335, base: "/",
    url: url_DescribeConstraint_600336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyProductStatus_600349 = ref object of OpenApiRestCall_599368
proc url_DescribeCopyProductStatus_600351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCopyProductStatus_600350(path: JsonNode; query: JsonNode;
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
  var valid_600352 = header.getOrDefault("X-Amz-Date")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Date", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Security-Token")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Security-Token", valid_600353
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600354 = header.getOrDefault("X-Amz-Target")
  valid_600354 = validateParameter(valid_600354, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeCopyProductStatus"))
  if valid_600354 != nil:
    section.add "X-Amz-Target", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Content-Sha256", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Algorithm")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Algorithm", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Signature")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Signature", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-SignedHeaders", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Credential")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Credential", valid_600359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600361: Call_DescribeCopyProductStatus_600349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified copy product operation.
  ## 
  let valid = call_600361.validator(path, query, header, formData, body)
  let scheme = call_600361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600361.url(scheme.get, call_600361.host, call_600361.base,
                         call_600361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600361, url, valid)

proc call*(call_600362: Call_DescribeCopyProductStatus_600349; body: JsonNode): Recallable =
  ## describeCopyProductStatus
  ## Gets the status of the specified copy product operation.
  ##   body: JObject (required)
  var body_600363 = newJObject()
  if body != nil:
    body_600363 = body
  result = call_600362.call(nil, nil, nil, nil, body_600363)

var describeCopyProductStatus* = Call_DescribeCopyProductStatus_600349(
    name: "describeCopyProductStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus",
    validator: validate_DescribeCopyProductStatus_600350, base: "/",
    url: url_DescribeCopyProductStatus_600351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolio_600364 = ref object of OpenApiRestCall_599368
proc url_DescribePortfolio_600366(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePortfolio_600365(path: JsonNode; query: JsonNode;
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
  var valid_600367 = header.getOrDefault("X-Amz-Date")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Date", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Security-Token")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Security-Token", valid_600368
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600369 = header.getOrDefault("X-Amz-Target")
  valid_600369 = validateParameter(valid_600369, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolio"))
  if valid_600369 != nil:
    section.add "X-Amz-Target", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Content-Sha256", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Algorithm")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Algorithm", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Signature")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Signature", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-SignedHeaders", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Credential")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Credential", valid_600374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600376: Call_DescribePortfolio_600364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified portfolio.
  ## 
  let valid = call_600376.validator(path, query, header, formData, body)
  let scheme = call_600376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600376.url(scheme.get, call_600376.host, call_600376.base,
                         call_600376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600376, url, valid)

proc call*(call_600377: Call_DescribePortfolio_600364; body: JsonNode): Recallable =
  ## describePortfolio
  ## Gets information about the specified portfolio.
  ##   body: JObject (required)
  var body_600378 = newJObject()
  if body != nil:
    body_600378 = body
  result = call_600377.call(nil, nil, nil, nil, body_600378)

var describePortfolio* = Call_DescribePortfolio_600364(name: "describePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio",
    validator: validate_DescribePortfolio_600365, base: "/",
    url: url_DescribePortfolio_600366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolioShareStatus_600379 = ref object of OpenApiRestCall_599368
proc url_DescribePortfolioShareStatus_600381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePortfolioShareStatus_600380(path: JsonNode; query: JsonNode;
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
  var valid_600382 = header.getOrDefault("X-Amz-Date")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Date", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Security-Token")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Security-Token", valid_600383
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600384 = header.getOrDefault("X-Amz-Target")
  valid_600384 = validateParameter(valid_600384, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolioShareStatus"))
  if valid_600384 != nil:
    section.add "X-Amz-Target", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Content-Sha256", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Algorithm")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Algorithm", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Signature")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Signature", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-SignedHeaders", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Credential")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Credential", valid_600389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600391: Call_DescribePortfolioShareStatus_600379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ## 
  let valid = call_600391.validator(path, query, header, formData, body)
  let scheme = call_600391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600391.url(scheme.get, call_600391.host, call_600391.base,
                         call_600391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600391, url, valid)

proc call*(call_600392: Call_DescribePortfolioShareStatus_600379; body: JsonNode): Recallable =
  ## describePortfolioShareStatus
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_600393 = newJObject()
  if body != nil:
    body_600393 = body
  result = call_600392.call(nil, nil, nil, nil, body_600393)

var describePortfolioShareStatus* = Call_DescribePortfolioShareStatus_600379(
    name: "describePortfolioShareStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus",
    validator: validate_DescribePortfolioShareStatus_600380, base: "/",
    url: url_DescribePortfolioShareStatus_600381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProduct_600394 = ref object of OpenApiRestCall_599368
proc url_DescribeProduct_600396(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProduct_600395(path: JsonNode; query: JsonNode;
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
  var valid_600397 = header.getOrDefault("X-Amz-Date")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Date", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Security-Token")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Security-Token", valid_600398
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600399 = header.getOrDefault("X-Amz-Target")
  valid_600399 = validateParameter(valid_600399, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProduct"))
  if valid_600399 != nil:
    section.add "X-Amz-Target", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Content-Sha256", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Algorithm")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Algorithm", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Signature")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Signature", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-SignedHeaders", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Credential")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Credential", valid_600404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600406: Call_DescribeProduct_600394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_600406.validator(path, query, header, formData, body)
  let scheme = call_600406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600406.url(scheme.get, call_600406.host, call_600406.base,
                         call_600406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600406, url, valid)

proc call*(call_600407: Call_DescribeProduct_600394; body: JsonNode): Recallable =
  ## describeProduct
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_600408 = newJObject()
  if body != nil:
    body_600408 = body
  result = call_600407.call(nil, nil, nil, nil, body_600408)

var describeProduct* = Call_DescribeProduct_600394(name: "describeProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct",
    validator: validate_DescribeProduct_600395, base: "/", url: url_DescribeProduct_600396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductAsAdmin_600409 = ref object of OpenApiRestCall_599368
proc url_DescribeProductAsAdmin_600411(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProductAsAdmin_600410(path: JsonNode; query: JsonNode;
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
  var valid_600412 = header.getOrDefault("X-Amz-Date")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Date", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Security-Token")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Security-Token", valid_600413
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600414 = header.getOrDefault("X-Amz-Target")
  valid_600414 = validateParameter(valid_600414, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductAsAdmin"))
  if valid_600414 != nil:
    section.add "X-Amz-Target", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Content-Sha256", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Algorithm")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Algorithm", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Signature")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Signature", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-SignedHeaders", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Credential")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Credential", valid_600419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600421: Call_DescribeProductAsAdmin_600409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product. This operation is run with administrator access.
  ## 
  let valid = call_600421.validator(path, query, header, formData, body)
  let scheme = call_600421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600421.url(scheme.get, call_600421.host, call_600421.base,
                         call_600421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600421, url, valid)

proc call*(call_600422: Call_DescribeProductAsAdmin_600409; body: JsonNode): Recallable =
  ## describeProductAsAdmin
  ## Gets information about the specified product. This operation is run with administrator access.
  ##   body: JObject (required)
  var body_600423 = newJObject()
  if body != nil:
    body_600423 = body
  result = call_600422.call(nil, nil, nil, nil, body_600423)

var describeProductAsAdmin* = Call_DescribeProductAsAdmin_600409(
    name: "describeProductAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin",
    validator: validate_DescribeProductAsAdmin_600410, base: "/",
    url: url_DescribeProductAsAdmin_600411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductView_600424 = ref object of OpenApiRestCall_599368
proc url_DescribeProductView_600426(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProductView_600425(path: JsonNode; query: JsonNode;
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
  var valid_600427 = header.getOrDefault("X-Amz-Date")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Date", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-Security-Token")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Security-Token", valid_600428
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600429 = header.getOrDefault("X-Amz-Target")
  valid_600429 = validateParameter(valid_600429, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductView"))
  if valid_600429 != nil:
    section.add "X-Amz-Target", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Content-Sha256", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Algorithm")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Algorithm", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Signature")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Signature", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-SignedHeaders", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Credential")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Credential", valid_600434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600436: Call_DescribeProductView_600424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_600436.validator(path, query, header, formData, body)
  let scheme = call_600436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600436.url(scheme.get, call_600436.host, call_600436.base,
                         call_600436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600436, url, valid)

proc call*(call_600437: Call_DescribeProductView_600424; body: JsonNode): Recallable =
  ## describeProductView
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_600438 = newJObject()
  if body != nil:
    body_600438 = body
  result = call_600437.call(nil, nil, nil, nil, body_600438)

var describeProductView* = Call_DescribeProductView_600424(
    name: "describeProductView", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView",
    validator: validate_DescribeProductView_600425, base: "/",
    url: url_DescribeProductView_600426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProduct_600439 = ref object of OpenApiRestCall_599368
proc url_DescribeProvisionedProduct_600441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisionedProduct_600440(path: JsonNode; query: JsonNode;
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
  var valid_600442 = header.getOrDefault("X-Amz-Date")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Date", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Security-Token")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Security-Token", valid_600443
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600444 = header.getOrDefault("X-Amz-Target")
  valid_600444 = validateParameter(valid_600444, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProduct"))
  if valid_600444 != nil:
    section.add "X-Amz-Target", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Content-Sha256", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-Algorithm")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Algorithm", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Signature")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Signature", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-SignedHeaders", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Credential")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Credential", valid_600449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600451: Call_DescribeProvisionedProduct_600439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioned product.
  ## 
  let valid = call_600451.validator(path, query, header, formData, body)
  let scheme = call_600451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600451.url(scheme.get, call_600451.host, call_600451.base,
                         call_600451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600451, url, valid)

proc call*(call_600452: Call_DescribeProvisionedProduct_600439; body: JsonNode): Recallable =
  ## describeProvisionedProduct
  ## Gets information about the specified provisioned product.
  ##   body: JObject (required)
  var body_600453 = newJObject()
  if body != nil:
    body_600453 = body
  result = call_600452.call(nil, nil, nil, nil, body_600453)

var describeProvisionedProduct* = Call_DescribeProvisionedProduct_600439(
    name: "describeProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct",
    validator: validate_DescribeProvisionedProduct_600440, base: "/",
    url: url_DescribeProvisionedProduct_600441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProductPlan_600454 = ref object of OpenApiRestCall_599368
proc url_DescribeProvisionedProductPlan_600456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisionedProductPlan_600455(path: JsonNode;
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
  var valid_600457 = header.getOrDefault("X-Amz-Date")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Date", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Security-Token")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Security-Token", valid_600458
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600459 = header.getOrDefault("X-Amz-Target")
  valid_600459 = validateParameter(valid_600459, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProductPlan"))
  if valid_600459 != nil:
    section.add "X-Amz-Target", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Content-Sha256", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Algorithm")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Algorithm", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Signature")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Signature", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-SignedHeaders", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Credential")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Credential", valid_600464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600466: Call_DescribeProvisionedProductPlan_600454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the resource changes for the specified plan.
  ## 
  let valid = call_600466.validator(path, query, header, formData, body)
  let scheme = call_600466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600466.url(scheme.get, call_600466.host, call_600466.base,
                         call_600466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600466, url, valid)

proc call*(call_600467: Call_DescribeProvisionedProductPlan_600454; body: JsonNode): Recallable =
  ## describeProvisionedProductPlan
  ## Gets information about the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_600468 = newJObject()
  if body != nil:
    body_600468 = body
  result = call_600467.call(nil, nil, nil, nil, body_600468)

var describeProvisionedProductPlan* = Call_DescribeProvisionedProductPlan_600454(
    name: "describeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan",
    validator: validate_DescribeProvisionedProductPlan_600455, base: "/",
    url: url_DescribeProvisionedProductPlan_600456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningArtifact_600469 = ref object of OpenApiRestCall_599368
proc url_DescribeProvisioningArtifact_600471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisioningArtifact_600470(path: JsonNode; query: JsonNode;
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
  var valid_600472 = header.getOrDefault("X-Amz-Date")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Date", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Security-Token")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Security-Token", valid_600473
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600474 = header.getOrDefault("X-Amz-Target")
  valid_600474 = validateParameter(valid_600474, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningArtifact"))
  if valid_600474 != nil:
    section.add "X-Amz-Target", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Content-Sha256", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Algorithm")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Algorithm", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Signature")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Signature", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-SignedHeaders", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Credential")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Credential", valid_600479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600481: Call_DescribeProvisioningArtifact_600469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ## 
  let valid = call_600481.validator(path, query, header, formData, body)
  let scheme = call_600481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600481.url(scheme.get, call_600481.host, call_600481.base,
                         call_600481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600481, url, valid)

proc call*(call_600482: Call_DescribeProvisioningArtifact_600469; body: JsonNode): Recallable =
  ## describeProvisioningArtifact
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ##   body: JObject (required)
  var body_600483 = newJObject()
  if body != nil:
    body_600483 = body
  result = call_600482.call(nil, nil, nil, nil, body_600483)

var describeProvisioningArtifact* = Call_DescribeProvisioningArtifact_600469(
    name: "describeProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact",
    validator: validate_DescribeProvisioningArtifact_600470, base: "/",
    url: url_DescribeProvisioningArtifact_600471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningParameters_600484 = ref object of OpenApiRestCall_599368
proc url_DescribeProvisioningParameters_600486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisioningParameters_600485(path: JsonNode;
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
  var valid_600487 = header.getOrDefault("X-Amz-Date")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Date", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Security-Token")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Security-Token", valid_600488
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600489 = header.getOrDefault("X-Amz-Target")
  valid_600489 = validateParameter(valid_600489, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningParameters"))
  if valid_600489 != nil:
    section.add "X-Amz-Target", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Content-Sha256", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Algorithm")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Algorithm", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Signature")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Signature", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-SignedHeaders", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Credential")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Credential", valid_600494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600496: Call_DescribeProvisioningParameters_600484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ## 
  let valid = call_600496.validator(path, query, header, formData, body)
  let scheme = call_600496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600496.url(scheme.get, call_600496.host, call_600496.base,
                         call_600496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600496, url, valid)

proc call*(call_600497: Call_DescribeProvisioningParameters_600484; body: JsonNode): Recallable =
  ## describeProvisioningParameters
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ##   body: JObject (required)
  var body_600498 = newJObject()
  if body != nil:
    body_600498 = body
  result = call_600497.call(nil, nil, nil, nil, body_600498)

var describeProvisioningParameters* = Call_DescribeProvisioningParameters_600484(
    name: "describeProvisioningParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters",
    validator: validate_DescribeProvisioningParameters_600485, base: "/",
    url: url_DescribeProvisioningParameters_600486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecord_600499 = ref object of OpenApiRestCall_599368
proc url_DescribeRecord_600501(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRecord_600500(path: JsonNode; query: JsonNode;
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
  var valid_600502 = header.getOrDefault("X-Amz-Date")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Date", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Security-Token")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Security-Token", valid_600503
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600504 = header.getOrDefault("X-Amz-Target")
  valid_600504 = validateParameter(valid_600504, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeRecord"))
  if valid_600504 != nil:
    section.add "X-Amz-Target", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Content-Sha256", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Algorithm")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Algorithm", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Signature")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Signature", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-SignedHeaders", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Credential")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Credential", valid_600509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600511: Call_DescribeRecord_600499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ## 
  let valid = call_600511.validator(path, query, header, formData, body)
  let scheme = call_600511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600511.url(scheme.get, call_600511.host, call_600511.base,
                         call_600511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600511, url, valid)

proc call*(call_600512: Call_DescribeRecord_600499; body: JsonNode): Recallable =
  ## describeRecord
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ##   body: JObject (required)
  var body_600513 = newJObject()
  if body != nil:
    body_600513 = body
  result = call_600512.call(nil, nil, nil, nil, body_600513)

var describeRecord* = Call_DescribeRecord_600499(name: "describeRecord",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord",
    validator: validate_DescribeRecord_600500, base: "/", url: url_DescribeRecord_600501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceAction_600514 = ref object of OpenApiRestCall_599368
proc url_DescribeServiceAction_600516(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServiceAction_600515(path: JsonNode; query: JsonNode;
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
  var valid_600517 = header.getOrDefault("X-Amz-Date")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Date", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Security-Token")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Security-Token", valid_600518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600519 = header.getOrDefault("X-Amz-Target")
  valid_600519 = validateParameter(valid_600519, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceAction"))
  if valid_600519 != nil:
    section.add "X-Amz-Target", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Content-Sha256", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Algorithm")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Algorithm", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Signature")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Signature", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-SignedHeaders", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Credential")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Credential", valid_600524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600526: Call_DescribeServiceAction_600514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a self-service action.
  ## 
  let valid = call_600526.validator(path, query, header, formData, body)
  let scheme = call_600526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600526.url(scheme.get, call_600526.host, call_600526.base,
                         call_600526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600526, url, valid)

proc call*(call_600527: Call_DescribeServiceAction_600514; body: JsonNode): Recallable =
  ## describeServiceAction
  ## Describes a self-service action.
  ##   body: JObject (required)
  var body_600528 = newJObject()
  if body != nil:
    body_600528 = body
  result = call_600527.call(nil, nil, nil, nil, body_600528)

var describeServiceAction* = Call_DescribeServiceAction_600514(
    name: "describeServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction",
    validator: validate_DescribeServiceAction_600515, base: "/",
    url: url_DescribeServiceAction_600516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceActionExecutionParameters_600529 = ref object of OpenApiRestCall_599368
proc url_DescribeServiceActionExecutionParameters_600531(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServiceActionExecutionParameters_600530(path: JsonNode;
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
  var valid_600532 = header.getOrDefault("X-Amz-Date")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Date", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Security-Token")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Security-Token", valid_600533
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600534 = header.getOrDefault("X-Amz-Target")
  valid_600534 = validateParameter(valid_600534, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"))
  if valid_600534 != nil:
    section.add "X-Amz-Target", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Content-Sha256", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Algorithm")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Algorithm", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Signature")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Signature", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-SignedHeaders", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Credential")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Credential", valid_600539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600541: Call_DescribeServiceActionExecutionParameters_600529;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_600541.validator(path, query, header, formData, body)
  let scheme = call_600541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600541.url(scheme.get, call_600541.host, call_600541.base,
                         call_600541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600541, url, valid)

proc call*(call_600542: Call_DescribeServiceActionExecutionParameters_600529;
          body: JsonNode): Recallable =
  ## describeServiceActionExecutionParameters
  ##   body: JObject (required)
  var body_600543 = newJObject()
  if body != nil:
    body_600543 = body
  result = call_600542.call(nil, nil, nil, nil, body_600543)

var describeServiceActionExecutionParameters* = Call_DescribeServiceActionExecutionParameters_600529(
    name: "describeServiceActionExecutionParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters",
    validator: validate_DescribeServiceActionExecutionParameters_600530,
    base: "/", url: url_DescribeServiceActionExecutionParameters_600531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTagOption_600544 = ref object of OpenApiRestCall_599368
proc url_DescribeTagOption_600546(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTagOption_600545(path: JsonNode; query: JsonNode;
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
  var valid_600547 = header.getOrDefault("X-Amz-Date")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-Date", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Security-Token")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Security-Token", valid_600548
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600549 = header.getOrDefault("X-Amz-Target")
  valid_600549 = validateParameter(valid_600549, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeTagOption"))
  if valid_600549 != nil:
    section.add "X-Amz-Target", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Content-Sha256", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Algorithm")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Algorithm", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Signature")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Signature", valid_600552
  var valid_600553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-SignedHeaders", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Credential")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Credential", valid_600554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600556: Call_DescribeTagOption_600544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified TagOption.
  ## 
  let valid = call_600556.validator(path, query, header, formData, body)
  let scheme = call_600556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600556.url(scheme.get, call_600556.host, call_600556.base,
                         call_600556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600556, url, valid)

proc call*(call_600557: Call_DescribeTagOption_600544; body: JsonNode): Recallable =
  ## describeTagOption
  ## Gets information about the specified TagOption.
  ##   body: JObject (required)
  var body_600558 = newJObject()
  if body != nil:
    body_600558 = body
  result = call_600557.call(nil, nil, nil, nil, body_600558)

var describeTagOption* = Call_DescribeTagOption_600544(name: "describeTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption",
    validator: validate_DescribeTagOption_600545, base: "/",
    url: url_DescribeTagOption_600546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSOrganizationsAccess_600559 = ref object of OpenApiRestCall_599368
proc url_DisableAWSOrganizationsAccess_600561(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableAWSOrganizationsAccess_600560(path: JsonNode; query: JsonNode;
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
  var valid_600562 = header.getOrDefault("X-Amz-Date")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Date", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-Security-Token")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Security-Token", valid_600563
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600564 = header.getOrDefault("X-Amz-Target")
  valid_600564 = validateParameter(valid_600564, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"))
  if valid_600564 != nil:
    section.add "X-Amz-Target", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Content-Sha256", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Algorithm")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Algorithm", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Signature")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Signature", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-SignedHeaders", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-Credential")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Credential", valid_600569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600571: Call_DisableAWSOrganizationsAccess_600559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ## 
  let valid = call_600571.validator(path, query, header, formData, body)
  let scheme = call_600571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600571.url(scheme.get, call_600571.host, call_600571.base,
                         call_600571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600571, url, valid)

proc call*(call_600572: Call_DisableAWSOrganizationsAccess_600559; body: JsonNode): Recallable =
  ## disableAWSOrganizationsAccess
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_600573 = newJObject()
  if body != nil:
    body_600573 = body
  result = call_600572.call(nil, nil, nil, nil, body_600573)

var disableAWSOrganizationsAccess* = Call_DisableAWSOrganizationsAccess_600559(
    name: "disableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess",
    validator: validate_DisableAWSOrganizationsAccess_600560, base: "/",
    url: url_DisableAWSOrganizationsAccess_600561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateBudgetFromResource_600574 = ref object of OpenApiRestCall_599368
proc url_DisassociateBudgetFromResource_600576(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateBudgetFromResource_600575(path: JsonNode;
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
  var valid_600577 = header.getOrDefault("X-Amz-Date")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Date", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Security-Token")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Security-Token", valid_600578
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600579 = header.getOrDefault("X-Amz-Target")
  valid_600579 = validateParameter(valid_600579, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateBudgetFromResource"))
  if valid_600579 != nil:
    section.add "X-Amz-Target", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Content-Sha256", valid_600580
  var valid_600581 = header.getOrDefault("X-Amz-Algorithm")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-Algorithm", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-Signature")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Signature", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-SignedHeaders", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Credential")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Credential", valid_600584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600586: Call_DisassociateBudgetFromResource_600574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified budget from the specified resource.
  ## 
  let valid = call_600586.validator(path, query, header, formData, body)
  let scheme = call_600586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600586.url(scheme.get, call_600586.host, call_600586.base,
                         call_600586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600586, url, valid)

proc call*(call_600587: Call_DisassociateBudgetFromResource_600574; body: JsonNode): Recallable =
  ## disassociateBudgetFromResource
  ## Disassociates the specified budget from the specified resource.
  ##   body: JObject (required)
  var body_600588 = newJObject()
  if body != nil:
    body_600588 = body
  result = call_600587.call(nil, nil, nil, nil, body_600588)

var disassociateBudgetFromResource* = Call_DisassociateBudgetFromResource_600574(
    name: "disassociateBudgetFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource",
    validator: validate_DisassociateBudgetFromResource_600575, base: "/",
    url: url_DisassociateBudgetFromResource_600576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePrincipalFromPortfolio_600589 = ref object of OpenApiRestCall_599368
proc url_DisassociatePrincipalFromPortfolio_600591(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociatePrincipalFromPortfolio_600590(path: JsonNode;
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
  var valid_600592 = header.getOrDefault("X-Amz-Date")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Date", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Security-Token")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Security-Token", valid_600593
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600594 = header.getOrDefault("X-Amz-Target")
  valid_600594 = validateParameter(valid_600594, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"))
  if valid_600594 != nil:
    section.add "X-Amz-Target", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Content-Sha256", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-Algorithm")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Algorithm", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Signature")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Signature", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-SignedHeaders", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Credential")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Credential", valid_600599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600601: Call_DisassociatePrincipalFromPortfolio_600589;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ## 
  let valid = call_600601.validator(path, query, header, formData, body)
  let scheme = call_600601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600601.url(scheme.get, call_600601.host, call_600601.base,
                         call_600601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600601, url, valid)

proc call*(call_600602: Call_DisassociatePrincipalFromPortfolio_600589;
          body: JsonNode): Recallable =
  ## disassociatePrincipalFromPortfolio
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ##   body: JObject (required)
  var body_600603 = newJObject()
  if body != nil:
    body_600603 = body
  result = call_600602.call(nil, nil, nil, nil, body_600603)

var disassociatePrincipalFromPortfolio* = Call_DisassociatePrincipalFromPortfolio_600589(
    name: "disassociatePrincipalFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio",
    validator: validate_DisassociatePrincipalFromPortfolio_600590, base: "/",
    url: url_DisassociatePrincipalFromPortfolio_600591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateProductFromPortfolio_600604 = ref object of OpenApiRestCall_599368
proc url_DisassociateProductFromPortfolio_600606(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateProductFromPortfolio_600605(path: JsonNode;
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
  var valid_600607 = header.getOrDefault("X-Amz-Date")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Date", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Security-Token")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Security-Token", valid_600608
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600609 = header.getOrDefault("X-Amz-Target")
  valid_600609 = validateParameter(valid_600609, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateProductFromPortfolio"))
  if valid_600609 != nil:
    section.add "X-Amz-Target", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Content-Sha256", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Algorithm")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Algorithm", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Signature")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Signature", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-SignedHeaders", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-Credential")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Credential", valid_600614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600616: Call_DisassociateProductFromPortfolio_600604;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified product from the specified portfolio. 
  ## 
  let valid = call_600616.validator(path, query, header, formData, body)
  let scheme = call_600616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600616.url(scheme.get, call_600616.host, call_600616.base,
                         call_600616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600616, url, valid)

proc call*(call_600617: Call_DisassociateProductFromPortfolio_600604;
          body: JsonNode): Recallable =
  ## disassociateProductFromPortfolio
  ## Disassociates the specified product from the specified portfolio. 
  ##   body: JObject (required)
  var body_600618 = newJObject()
  if body != nil:
    body_600618 = body
  result = call_600617.call(nil, nil, nil, nil, body_600618)

var disassociateProductFromPortfolio* = Call_DisassociateProductFromPortfolio_600604(
    name: "disassociateProductFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio",
    validator: validate_DisassociateProductFromPortfolio_600605, base: "/",
    url: url_DisassociateProductFromPortfolio_600606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceActionFromProvisioningArtifact_600619 = ref object of OpenApiRestCall_599368
proc url_DisassociateServiceActionFromProvisioningArtifact_600621(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceActionFromProvisioningArtifact_600620(
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
  var valid_600622 = header.getOrDefault("X-Amz-Date")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Date", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Security-Token")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Security-Token", valid_600623
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600624 = header.getOrDefault("X-Amz-Target")
  valid_600624 = validateParameter(valid_600624, JString, required = true, default = newJString("AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"))
  if valid_600624 != nil:
    section.add "X-Amz-Target", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Content-Sha256", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Algorithm")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Algorithm", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Signature")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Signature", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-SignedHeaders", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Credential")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Credential", valid_600629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600631: Call_DisassociateServiceActionFromProvisioningArtifact_600619;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ## 
  let valid = call_600631.validator(path, query, header, formData, body)
  let scheme = call_600631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600631.url(scheme.get, call_600631.host, call_600631.base,
                         call_600631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600631, url, valid)

proc call*(call_600632: Call_DisassociateServiceActionFromProvisioningArtifact_600619;
          body: JsonNode): Recallable =
  ## disassociateServiceActionFromProvisioningArtifact
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_600633 = newJObject()
  if body != nil:
    body_600633 = body
  result = call_600632.call(nil, nil, nil, nil, body_600633)

var disassociateServiceActionFromProvisioningArtifact* = Call_DisassociateServiceActionFromProvisioningArtifact_600619(
    name: "disassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact",
    validator: validate_DisassociateServiceActionFromProvisioningArtifact_600620,
    base: "/", url: url_DisassociateServiceActionFromProvisioningArtifact_600621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTagOptionFromResource_600634 = ref object of OpenApiRestCall_599368
proc url_DisassociateTagOptionFromResource_600636(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateTagOptionFromResource_600635(path: JsonNode;
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
  var valid_600637 = header.getOrDefault("X-Amz-Date")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Date", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Security-Token")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Security-Token", valid_600638
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600639 = header.getOrDefault("X-Amz-Target")
  valid_600639 = validateParameter(valid_600639, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateTagOptionFromResource"))
  if valid_600639 != nil:
    section.add "X-Amz-Target", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Content-Sha256", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Algorithm")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Algorithm", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Signature")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Signature", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-SignedHeaders", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-Credential")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Credential", valid_600644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600646: Call_DisassociateTagOptionFromResource_600634;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified TagOption from the specified resource.
  ## 
  let valid = call_600646.validator(path, query, header, formData, body)
  let scheme = call_600646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600646.url(scheme.get, call_600646.host, call_600646.base,
                         call_600646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600646, url, valid)

proc call*(call_600647: Call_DisassociateTagOptionFromResource_600634;
          body: JsonNode): Recallable =
  ## disassociateTagOptionFromResource
  ## Disassociates the specified TagOption from the specified resource.
  ##   body: JObject (required)
  var body_600648 = newJObject()
  if body != nil:
    body_600648 = body
  result = call_600647.call(nil, nil, nil, nil, body_600648)

var disassociateTagOptionFromResource* = Call_DisassociateTagOptionFromResource_600634(
    name: "disassociateTagOptionFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource",
    validator: validate_DisassociateTagOptionFromResource_600635, base: "/",
    url: url_DisassociateTagOptionFromResource_600636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSOrganizationsAccess_600649 = ref object of OpenApiRestCall_599368
proc url_EnableAWSOrganizationsAccess_600651(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableAWSOrganizationsAccess_600650(path: JsonNode; query: JsonNode;
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
  var valid_600652 = header.getOrDefault("X-Amz-Date")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Date", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Security-Token")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Security-Token", valid_600653
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600654 = header.getOrDefault("X-Amz-Target")
  valid_600654 = validateParameter(valid_600654, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"))
  if valid_600654 != nil:
    section.add "X-Amz-Target", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Content-Sha256", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Algorithm")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Algorithm", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Signature")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Signature", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-SignedHeaders", valid_600658
  var valid_600659 = header.getOrDefault("X-Amz-Credential")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Credential", valid_600659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600661: Call_EnableAWSOrganizationsAccess_600649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ## 
  let valid = call_600661.validator(path, query, header, formData, body)
  let scheme = call_600661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600661.url(scheme.get, call_600661.host, call_600661.base,
                         call_600661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600661, url, valid)

proc call*(call_600662: Call_EnableAWSOrganizationsAccess_600649; body: JsonNode): Recallable =
  ## enableAWSOrganizationsAccess
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ##   body: JObject (required)
  var body_600663 = newJObject()
  if body != nil:
    body_600663 = body
  result = call_600662.call(nil, nil, nil, nil, body_600663)

var enableAWSOrganizationsAccess* = Call_EnableAWSOrganizationsAccess_600649(
    name: "enableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess",
    validator: validate_EnableAWSOrganizationsAccess_600650, base: "/",
    url: url_EnableAWSOrganizationsAccess_600651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductPlan_600664 = ref object of OpenApiRestCall_599368
proc url_ExecuteProvisionedProductPlan_600666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteProvisionedProductPlan_600665(path: JsonNode; query: JsonNode;
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
  var valid_600667 = header.getOrDefault("X-Amz-Date")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Date", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Security-Token")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Security-Token", valid_600668
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600669 = header.getOrDefault("X-Amz-Target")
  valid_600669 = validateParameter(valid_600669, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"))
  if valid_600669 != nil:
    section.add "X-Amz-Target", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Content-Sha256", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Algorithm")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Algorithm", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Signature")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Signature", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-SignedHeaders", valid_600673
  var valid_600674 = header.getOrDefault("X-Amz-Credential")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Credential", valid_600674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600676: Call_ExecuteProvisionedProductPlan_600664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ## 
  let valid = call_600676.validator(path, query, header, formData, body)
  let scheme = call_600676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600676.url(scheme.get, call_600676.host, call_600676.base,
                         call_600676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600676, url, valid)

proc call*(call_600677: Call_ExecuteProvisionedProductPlan_600664; body: JsonNode): Recallable =
  ## executeProvisionedProductPlan
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_600678 = newJObject()
  if body != nil:
    body_600678 = body
  result = call_600677.call(nil, nil, nil, nil, body_600678)

var executeProvisionedProductPlan* = Call_ExecuteProvisionedProductPlan_600664(
    name: "executeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan",
    validator: validate_ExecuteProvisionedProductPlan_600665, base: "/",
    url: url_ExecuteProvisionedProductPlan_600666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductServiceAction_600679 = ref object of OpenApiRestCall_599368
proc url_ExecuteProvisionedProductServiceAction_600681(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteProvisionedProductServiceAction_600680(path: JsonNode;
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
  var valid_600682 = header.getOrDefault("X-Amz-Date")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Date", valid_600682
  var valid_600683 = header.getOrDefault("X-Amz-Security-Token")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Security-Token", valid_600683
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600684 = header.getOrDefault("X-Amz-Target")
  valid_600684 = validateParameter(valid_600684, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"))
  if valid_600684 != nil:
    section.add "X-Amz-Target", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Content-Sha256", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-Algorithm")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Algorithm", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Signature")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Signature", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-SignedHeaders", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Credential")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Credential", valid_600689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600691: Call_ExecuteProvisionedProductServiceAction_600679;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Executes a self-service action against a provisioned product.
  ## 
  let valid = call_600691.validator(path, query, header, formData, body)
  let scheme = call_600691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600691.url(scheme.get, call_600691.host, call_600691.base,
                         call_600691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600691, url, valid)

proc call*(call_600692: Call_ExecuteProvisionedProductServiceAction_600679;
          body: JsonNode): Recallable =
  ## executeProvisionedProductServiceAction
  ## Executes a self-service action against a provisioned product.
  ##   body: JObject (required)
  var body_600693 = newJObject()
  if body != nil:
    body_600693 = body
  result = call_600692.call(nil, nil, nil, nil, body_600693)

var executeProvisionedProductServiceAction* = Call_ExecuteProvisionedProductServiceAction_600679(
    name: "executeProvisionedProductServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction",
    validator: validate_ExecuteProvisionedProductServiceAction_600680, base: "/",
    url: url_ExecuteProvisionedProductServiceAction_600681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSOrganizationsAccessStatus_600694 = ref object of OpenApiRestCall_599368
proc url_GetAWSOrganizationsAccessStatus_600696(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAWSOrganizationsAccessStatus_600695(path: JsonNode;
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
  var valid_600697 = header.getOrDefault("X-Amz-Date")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Date", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Security-Token")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Security-Token", valid_600698
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600699 = header.getOrDefault("X-Amz-Target")
  valid_600699 = validateParameter(valid_600699, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"))
  if valid_600699 != nil:
    section.add "X-Amz-Target", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Content-Sha256", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Algorithm")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Algorithm", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Signature")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Signature", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-SignedHeaders", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-Credential")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Credential", valid_600704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600706: Call_GetAWSOrganizationsAccessStatus_600694;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ## 
  let valid = call_600706.validator(path, query, header, formData, body)
  let scheme = call_600706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600706.url(scheme.get, call_600706.host, call_600706.base,
                         call_600706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600706, url, valid)

proc call*(call_600707: Call_GetAWSOrganizationsAccessStatus_600694; body: JsonNode): Recallable =
  ## getAWSOrganizationsAccessStatus
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_600708 = newJObject()
  if body != nil:
    body_600708 = body
  result = call_600707.call(nil, nil, nil, nil, body_600708)

var getAWSOrganizationsAccessStatus* = Call_GetAWSOrganizationsAccessStatus_600694(
    name: "getAWSOrganizationsAccessStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus",
    validator: validate_GetAWSOrganizationsAccessStatus_600695, base: "/",
    url: url_GetAWSOrganizationsAccessStatus_600696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAcceptedPortfolioShares_600709 = ref object of OpenApiRestCall_599368
proc url_ListAcceptedPortfolioShares_600711(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAcceptedPortfolioShares_600710(path: JsonNode; query: JsonNode;
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
  var valid_600712 = query.getOrDefault("PageSize")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "PageSize", valid_600712
  var valid_600713 = query.getOrDefault("PageToken")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "PageToken", valid_600713
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
  var valid_600714 = header.getOrDefault("X-Amz-Date")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-Date", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Security-Token")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Security-Token", valid_600715
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600716 = header.getOrDefault("X-Amz-Target")
  valid_600716 = validateParameter(valid_600716, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListAcceptedPortfolioShares"))
  if valid_600716 != nil:
    section.add "X-Amz-Target", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Content-Sha256", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-Algorithm")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-Algorithm", valid_600718
  var valid_600719 = header.getOrDefault("X-Amz-Signature")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-Signature", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-SignedHeaders", valid_600720
  var valid_600721 = header.getOrDefault("X-Amz-Credential")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "X-Amz-Credential", valid_600721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600723: Call_ListAcceptedPortfolioShares_600709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  let valid = call_600723.validator(path, query, header, formData, body)
  let scheme = call_600723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600723.url(scheme.get, call_600723.host, call_600723.base,
                         call_600723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600723, url, valid)

proc call*(call_600724: Call_ListAcceptedPortfolioShares_600709; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listAcceptedPortfolioShares
  ## Lists all portfolios for which sharing was accepted by this account.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600725 = newJObject()
  var body_600726 = newJObject()
  add(query_600725, "PageSize", newJString(PageSize))
  add(query_600725, "PageToken", newJString(PageToken))
  if body != nil:
    body_600726 = body
  result = call_600724.call(nil, query_600725, nil, nil, body_600726)

var listAcceptedPortfolioShares* = Call_ListAcceptedPortfolioShares_600709(
    name: "listAcceptedPortfolioShares", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares",
    validator: validate_ListAcceptedPortfolioShares_600710, base: "/",
    url: url_ListAcceptedPortfolioShares_600711,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBudgetsForResource_600728 = ref object of OpenApiRestCall_599368
proc url_ListBudgetsForResource_600730(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBudgetsForResource_600729(path: JsonNode; query: JsonNode;
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
  var valid_600731 = query.getOrDefault("PageSize")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "PageSize", valid_600731
  var valid_600732 = query.getOrDefault("PageToken")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "PageToken", valid_600732
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
  var valid_600733 = header.getOrDefault("X-Amz-Date")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-Date", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Security-Token")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Security-Token", valid_600734
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600735 = header.getOrDefault("X-Amz-Target")
  valid_600735 = validateParameter(valid_600735, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListBudgetsForResource"))
  if valid_600735 != nil:
    section.add "X-Amz-Target", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Content-Sha256", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-Algorithm")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Algorithm", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Signature")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Signature", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-SignedHeaders", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-Credential")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Credential", valid_600740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600742: Call_ListBudgetsForResource_600728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the budgets associated to the specified resource.
  ## 
  let valid = call_600742.validator(path, query, header, formData, body)
  let scheme = call_600742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600742.url(scheme.get, call_600742.host, call_600742.base,
                         call_600742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600742, url, valid)

proc call*(call_600743: Call_ListBudgetsForResource_600728; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listBudgetsForResource
  ## Lists all the budgets associated to the specified resource.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600744 = newJObject()
  var body_600745 = newJObject()
  add(query_600744, "PageSize", newJString(PageSize))
  add(query_600744, "PageToken", newJString(PageToken))
  if body != nil:
    body_600745 = body
  result = call_600743.call(nil, query_600744, nil, nil, body_600745)

var listBudgetsForResource* = Call_ListBudgetsForResource_600728(
    name: "listBudgetsForResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource",
    validator: validate_ListBudgetsForResource_600729, base: "/",
    url: url_ListBudgetsForResource_600730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConstraintsForPortfolio_600746 = ref object of OpenApiRestCall_599368
proc url_ListConstraintsForPortfolio_600748(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConstraintsForPortfolio_600747(path: JsonNode; query: JsonNode;
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
  var valid_600749 = query.getOrDefault("PageSize")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "PageSize", valid_600749
  var valid_600750 = query.getOrDefault("PageToken")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "PageToken", valid_600750
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
  var valid_600751 = header.getOrDefault("X-Amz-Date")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-Date", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-Security-Token")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-Security-Token", valid_600752
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600753 = header.getOrDefault("X-Amz-Target")
  valid_600753 = validateParameter(valid_600753, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListConstraintsForPortfolio"))
  if valid_600753 != nil:
    section.add "X-Amz-Target", valid_600753
  var valid_600754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "X-Amz-Content-Sha256", valid_600754
  var valid_600755 = header.getOrDefault("X-Amz-Algorithm")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "X-Amz-Algorithm", valid_600755
  var valid_600756 = header.getOrDefault("X-Amz-Signature")
  valid_600756 = validateParameter(valid_600756, JString, required = false,
                                 default = nil)
  if valid_600756 != nil:
    section.add "X-Amz-Signature", valid_600756
  var valid_600757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "X-Amz-SignedHeaders", valid_600757
  var valid_600758 = header.getOrDefault("X-Amz-Credential")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-Credential", valid_600758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600760: Call_ListConstraintsForPortfolio_600746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  let valid = call_600760.validator(path, query, header, formData, body)
  let scheme = call_600760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600760.url(scheme.get, call_600760.host, call_600760.base,
                         call_600760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600760, url, valid)

proc call*(call_600761: Call_ListConstraintsForPortfolio_600746; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listConstraintsForPortfolio
  ## Lists the constraints for the specified portfolio and product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600762 = newJObject()
  var body_600763 = newJObject()
  add(query_600762, "PageSize", newJString(PageSize))
  add(query_600762, "PageToken", newJString(PageToken))
  if body != nil:
    body_600763 = body
  result = call_600761.call(nil, query_600762, nil, nil, body_600763)

var listConstraintsForPortfolio* = Call_ListConstraintsForPortfolio_600746(
    name: "listConstraintsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio",
    validator: validate_ListConstraintsForPortfolio_600747, base: "/",
    url: url_ListConstraintsForPortfolio_600748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLaunchPaths_600764 = ref object of OpenApiRestCall_599368
proc url_ListLaunchPaths_600766(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLaunchPaths_600765(path: JsonNode; query: JsonNode;
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
  var valid_600767 = query.getOrDefault("PageSize")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "PageSize", valid_600767
  var valid_600768 = query.getOrDefault("PageToken")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "PageToken", valid_600768
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
  var valid_600769 = header.getOrDefault("X-Amz-Date")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-Date", valid_600769
  var valid_600770 = header.getOrDefault("X-Amz-Security-Token")
  valid_600770 = validateParameter(valid_600770, JString, required = false,
                                 default = nil)
  if valid_600770 != nil:
    section.add "X-Amz-Security-Token", valid_600770
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600771 = header.getOrDefault("X-Amz-Target")
  valid_600771 = validateParameter(valid_600771, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListLaunchPaths"))
  if valid_600771 != nil:
    section.add "X-Amz-Target", valid_600771
  var valid_600772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-Content-Sha256", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Algorithm")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Algorithm", valid_600773
  var valid_600774 = header.getOrDefault("X-Amz-Signature")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "X-Amz-Signature", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-SignedHeaders", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Credential")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Credential", valid_600776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600778: Call_ListLaunchPaths_600764; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  let valid = call_600778.validator(path, query, header, formData, body)
  let scheme = call_600778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600778.url(scheme.get, call_600778.host, call_600778.base,
                         call_600778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600778, url, valid)

proc call*(call_600779: Call_ListLaunchPaths_600764; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listLaunchPaths
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600780 = newJObject()
  var body_600781 = newJObject()
  add(query_600780, "PageSize", newJString(PageSize))
  add(query_600780, "PageToken", newJString(PageToken))
  if body != nil:
    body_600781 = body
  result = call_600779.call(nil, query_600780, nil, nil, body_600781)

var listLaunchPaths* = Call_ListLaunchPaths_600764(name: "listLaunchPaths",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths",
    validator: validate_ListLaunchPaths_600765, base: "/", url: url_ListLaunchPaths_600766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationPortfolioAccess_600782 = ref object of OpenApiRestCall_599368
proc url_ListOrganizationPortfolioAccess_600784(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOrganizationPortfolioAccess_600783(path: JsonNode;
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
  var valid_600785 = query.getOrDefault("PageSize")
  valid_600785 = validateParameter(valid_600785, JString, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "PageSize", valid_600785
  var valid_600786 = query.getOrDefault("PageToken")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "PageToken", valid_600786
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
  var valid_600787 = header.getOrDefault("X-Amz-Date")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-Date", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-Security-Token")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-Security-Token", valid_600788
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600789 = header.getOrDefault("X-Amz-Target")
  valid_600789 = validateParameter(valid_600789, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"))
  if valid_600789 != nil:
    section.add "X-Amz-Target", valid_600789
  var valid_600790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "X-Amz-Content-Sha256", valid_600790
  var valid_600791 = header.getOrDefault("X-Amz-Algorithm")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "X-Amz-Algorithm", valid_600791
  var valid_600792 = header.getOrDefault("X-Amz-Signature")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "X-Amz-Signature", valid_600792
  var valid_600793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "X-Amz-SignedHeaders", valid_600793
  var valid_600794 = header.getOrDefault("X-Amz-Credential")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "X-Amz-Credential", valid_600794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600796: Call_ListOrganizationPortfolioAccess_600782;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  let valid = call_600796.validator(path, query, header, formData, body)
  let scheme = call_600796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600796.url(scheme.get, call_600796.host, call_600796.base,
                         call_600796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600796, url, valid)

proc call*(call_600797: Call_ListOrganizationPortfolioAccess_600782;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listOrganizationPortfolioAccess
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600798 = newJObject()
  var body_600799 = newJObject()
  add(query_600798, "PageSize", newJString(PageSize))
  add(query_600798, "PageToken", newJString(PageToken))
  if body != nil:
    body_600799 = body
  result = call_600797.call(nil, query_600798, nil, nil, body_600799)

var listOrganizationPortfolioAccess* = Call_ListOrganizationPortfolioAccess_600782(
    name: "listOrganizationPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess",
    validator: validate_ListOrganizationPortfolioAccess_600783, base: "/",
    url: url_ListOrganizationPortfolioAccess_600784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolioAccess_600800 = ref object of OpenApiRestCall_599368
proc url_ListPortfolioAccess_600802(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfolioAccess_600801(path: JsonNode; query: JsonNode;
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
  var valid_600803 = header.getOrDefault("X-Amz-Date")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Date", valid_600803
  var valid_600804 = header.getOrDefault("X-Amz-Security-Token")
  valid_600804 = validateParameter(valid_600804, JString, required = false,
                                 default = nil)
  if valid_600804 != nil:
    section.add "X-Amz-Security-Token", valid_600804
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600805 = header.getOrDefault("X-Amz-Target")
  valid_600805 = validateParameter(valid_600805, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolioAccess"))
  if valid_600805 != nil:
    section.add "X-Amz-Target", valid_600805
  var valid_600806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600806 = validateParameter(valid_600806, JString, required = false,
                                 default = nil)
  if valid_600806 != nil:
    section.add "X-Amz-Content-Sha256", valid_600806
  var valid_600807 = header.getOrDefault("X-Amz-Algorithm")
  valid_600807 = validateParameter(valid_600807, JString, required = false,
                                 default = nil)
  if valid_600807 != nil:
    section.add "X-Amz-Algorithm", valid_600807
  var valid_600808 = header.getOrDefault("X-Amz-Signature")
  valid_600808 = validateParameter(valid_600808, JString, required = false,
                                 default = nil)
  if valid_600808 != nil:
    section.add "X-Amz-Signature", valid_600808
  var valid_600809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600809 = validateParameter(valid_600809, JString, required = false,
                                 default = nil)
  if valid_600809 != nil:
    section.add "X-Amz-SignedHeaders", valid_600809
  var valid_600810 = header.getOrDefault("X-Amz-Credential")
  valid_600810 = validateParameter(valid_600810, JString, required = false,
                                 default = nil)
  if valid_600810 != nil:
    section.add "X-Amz-Credential", valid_600810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600812: Call_ListPortfolioAccess_600800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account IDs that have access to the specified portfolio.
  ## 
  let valid = call_600812.validator(path, query, header, formData, body)
  let scheme = call_600812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600812.url(scheme.get, call_600812.host, call_600812.base,
                         call_600812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600812, url, valid)

proc call*(call_600813: Call_ListPortfolioAccess_600800; body: JsonNode): Recallable =
  ## listPortfolioAccess
  ## Lists the account IDs that have access to the specified portfolio.
  ##   body: JObject (required)
  var body_600814 = newJObject()
  if body != nil:
    body_600814 = body
  result = call_600813.call(nil, nil, nil, nil, body_600814)

var listPortfolioAccess* = Call_ListPortfolioAccess_600800(
    name: "listPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess",
    validator: validate_ListPortfolioAccess_600801, base: "/",
    url: url_ListPortfolioAccess_600802, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolios_600815 = ref object of OpenApiRestCall_599368
proc url_ListPortfolios_600817(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfolios_600816(path: JsonNode; query: JsonNode;
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
  var valid_600818 = query.getOrDefault("PageSize")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "PageSize", valid_600818
  var valid_600819 = query.getOrDefault("PageToken")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "PageToken", valid_600819
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
  var valid_600820 = header.getOrDefault("X-Amz-Date")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "X-Amz-Date", valid_600820
  var valid_600821 = header.getOrDefault("X-Amz-Security-Token")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "X-Amz-Security-Token", valid_600821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600822 = header.getOrDefault("X-Amz-Target")
  valid_600822 = validateParameter(valid_600822, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolios"))
  if valid_600822 != nil:
    section.add "X-Amz-Target", valid_600822
  var valid_600823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "X-Amz-Content-Sha256", valid_600823
  var valid_600824 = header.getOrDefault("X-Amz-Algorithm")
  valid_600824 = validateParameter(valid_600824, JString, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "X-Amz-Algorithm", valid_600824
  var valid_600825 = header.getOrDefault("X-Amz-Signature")
  valid_600825 = validateParameter(valid_600825, JString, required = false,
                                 default = nil)
  if valid_600825 != nil:
    section.add "X-Amz-Signature", valid_600825
  var valid_600826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600826 = validateParameter(valid_600826, JString, required = false,
                                 default = nil)
  if valid_600826 != nil:
    section.add "X-Amz-SignedHeaders", valid_600826
  var valid_600827 = header.getOrDefault("X-Amz-Credential")
  valid_600827 = validateParameter(valid_600827, JString, required = false,
                                 default = nil)
  if valid_600827 != nil:
    section.add "X-Amz-Credential", valid_600827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600829: Call_ListPortfolios_600815; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios in the catalog.
  ## 
  let valid = call_600829.validator(path, query, header, formData, body)
  let scheme = call_600829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600829.url(scheme.get, call_600829.host, call_600829.base,
                         call_600829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600829, url, valid)

proc call*(call_600830: Call_ListPortfolios_600815; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfolios
  ## Lists all portfolios in the catalog.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600831 = newJObject()
  var body_600832 = newJObject()
  add(query_600831, "PageSize", newJString(PageSize))
  add(query_600831, "PageToken", newJString(PageToken))
  if body != nil:
    body_600832 = body
  result = call_600830.call(nil, query_600831, nil, nil, body_600832)

var listPortfolios* = Call_ListPortfolios_600815(name: "listPortfolios",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios",
    validator: validate_ListPortfolios_600816, base: "/", url: url_ListPortfolios_600817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfoliosForProduct_600833 = ref object of OpenApiRestCall_599368
proc url_ListPortfoliosForProduct_600835(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfoliosForProduct_600834(path: JsonNode; query: JsonNode;
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
  var valid_600836 = query.getOrDefault("PageSize")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "PageSize", valid_600836
  var valid_600837 = query.getOrDefault("PageToken")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "PageToken", valid_600837
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
  var valid_600838 = header.getOrDefault("X-Amz-Date")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Date", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Security-Token")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Security-Token", valid_600839
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600840 = header.getOrDefault("X-Amz-Target")
  valid_600840 = validateParameter(valid_600840, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfoliosForProduct"))
  if valid_600840 != nil:
    section.add "X-Amz-Target", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Content-Sha256", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-Algorithm")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-Algorithm", valid_600842
  var valid_600843 = header.getOrDefault("X-Amz-Signature")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-Signature", valid_600843
  var valid_600844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "X-Amz-SignedHeaders", valid_600844
  var valid_600845 = header.getOrDefault("X-Amz-Credential")
  valid_600845 = validateParameter(valid_600845, JString, required = false,
                                 default = nil)
  if valid_600845 != nil:
    section.add "X-Amz-Credential", valid_600845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600847: Call_ListPortfoliosForProduct_600833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  let valid = call_600847.validator(path, query, header, formData, body)
  let scheme = call_600847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600847.url(scheme.get, call_600847.host, call_600847.base,
                         call_600847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600847, url, valid)

proc call*(call_600848: Call_ListPortfoliosForProduct_600833; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfoliosForProduct
  ## Lists all portfolios that the specified product is associated with.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600849 = newJObject()
  var body_600850 = newJObject()
  add(query_600849, "PageSize", newJString(PageSize))
  add(query_600849, "PageToken", newJString(PageToken))
  if body != nil:
    body_600850 = body
  result = call_600848.call(nil, query_600849, nil, nil, body_600850)

var listPortfoliosForProduct* = Call_ListPortfoliosForProduct_600833(
    name: "listPortfoliosForProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct",
    validator: validate_ListPortfoliosForProduct_600834, base: "/",
    url: url_ListPortfoliosForProduct_600835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipalsForPortfolio_600851 = ref object of OpenApiRestCall_599368
proc url_ListPrincipalsForPortfolio_600853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPrincipalsForPortfolio_600852(path: JsonNode; query: JsonNode;
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
  var valid_600854 = query.getOrDefault("PageSize")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "PageSize", valid_600854
  var valid_600855 = query.getOrDefault("PageToken")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "PageToken", valid_600855
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
  var valid_600856 = header.getOrDefault("X-Amz-Date")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Date", valid_600856
  var valid_600857 = header.getOrDefault("X-Amz-Security-Token")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "X-Amz-Security-Token", valid_600857
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600858 = header.getOrDefault("X-Amz-Target")
  valid_600858 = validateParameter(valid_600858, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPrincipalsForPortfolio"))
  if valid_600858 != nil:
    section.add "X-Amz-Target", valid_600858
  var valid_600859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "X-Amz-Content-Sha256", valid_600859
  var valid_600860 = header.getOrDefault("X-Amz-Algorithm")
  valid_600860 = validateParameter(valid_600860, JString, required = false,
                                 default = nil)
  if valid_600860 != nil:
    section.add "X-Amz-Algorithm", valid_600860
  var valid_600861 = header.getOrDefault("X-Amz-Signature")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-Signature", valid_600861
  var valid_600862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "X-Amz-SignedHeaders", valid_600862
  var valid_600863 = header.getOrDefault("X-Amz-Credential")
  valid_600863 = validateParameter(valid_600863, JString, required = false,
                                 default = nil)
  if valid_600863 != nil:
    section.add "X-Amz-Credential", valid_600863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600865: Call_ListPrincipalsForPortfolio_600851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  let valid = call_600865.validator(path, query, header, formData, body)
  let scheme = call_600865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600865.url(scheme.get, call_600865.host, call_600865.base,
                         call_600865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600865, url, valid)

proc call*(call_600866: Call_ListPrincipalsForPortfolio_600851; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPrincipalsForPortfolio
  ## Lists all principal ARNs associated with the specified portfolio.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600867 = newJObject()
  var body_600868 = newJObject()
  add(query_600867, "PageSize", newJString(PageSize))
  add(query_600867, "PageToken", newJString(PageToken))
  if body != nil:
    body_600868 = body
  result = call_600866.call(nil, query_600867, nil, nil, body_600868)

var listPrincipalsForPortfolio* = Call_ListPrincipalsForPortfolio_600851(
    name: "listPrincipalsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio",
    validator: validate_ListPrincipalsForPortfolio_600852, base: "/",
    url: url_ListPrincipalsForPortfolio_600853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedProductPlans_600869 = ref object of OpenApiRestCall_599368
proc url_ListProvisionedProductPlans_600871(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisionedProductPlans_600870(path: JsonNode; query: JsonNode;
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
  var valid_600872 = header.getOrDefault("X-Amz-Date")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Date", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Security-Token")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Security-Token", valid_600873
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600874 = header.getOrDefault("X-Amz-Target")
  valid_600874 = validateParameter(valid_600874, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisionedProductPlans"))
  if valid_600874 != nil:
    section.add "X-Amz-Target", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Content-Sha256", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-Algorithm")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-Algorithm", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-Signature")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Signature", valid_600877
  var valid_600878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600878 = validateParameter(valid_600878, JString, required = false,
                                 default = nil)
  if valid_600878 != nil:
    section.add "X-Amz-SignedHeaders", valid_600878
  var valid_600879 = header.getOrDefault("X-Amz-Credential")
  valid_600879 = validateParameter(valid_600879, JString, required = false,
                                 default = nil)
  if valid_600879 != nil:
    section.add "X-Amz-Credential", valid_600879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600881: Call_ListProvisionedProductPlans_600869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ## 
  let valid = call_600881.validator(path, query, header, formData, body)
  let scheme = call_600881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600881.url(scheme.get, call_600881.host, call_600881.base,
                         call_600881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600881, url, valid)

proc call*(call_600882: Call_ListProvisionedProductPlans_600869; body: JsonNode): Recallable =
  ## listProvisionedProductPlans
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ##   body: JObject (required)
  var body_600883 = newJObject()
  if body != nil:
    body_600883 = body
  result = call_600882.call(nil, nil, nil, nil, body_600883)

var listProvisionedProductPlans* = Call_ListProvisionedProductPlans_600869(
    name: "listProvisionedProductPlans", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans",
    validator: validate_ListProvisionedProductPlans_600870, base: "/",
    url: url_ListProvisionedProductPlans_600871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifacts_600884 = ref object of OpenApiRestCall_599368
proc url_ListProvisioningArtifacts_600886(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisioningArtifacts_600885(path: JsonNode; query: JsonNode;
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
  var valid_600887 = header.getOrDefault("X-Amz-Date")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Date", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Security-Token")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Security-Token", valid_600888
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600889 = header.getOrDefault("X-Amz-Target")
  valid_600889 = validateParameter(valid_600889, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifacts"))
  if valid_600889 != nil:
    section.add "X-Amz-Target", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Content-Sha256", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Algorithm")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Algorithm", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Signature")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Signature", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-SignedHeaders", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Credential")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Credential", valid_600894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600896: Call_ListProvisioningArtifacts_600884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ## 
  let valid = call_600896.validator(path, query, header, formData, body)
  let scheme = call_600896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600896.url(scheme.get, call_600896.host, call_600896.base,
                         call_600896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600896, url, valid)

proc call*(call_600897: Call_ListProvisioningArtifacts_600884; body: JsonNode): Recallable =
  ## listProvisioningArtifacts
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ##   body: JObject (required)
  var body_600898 = newJObject()
  if body != nil:
    body_600898 = body
  result = call_600897.call(nil, nil, nil, nil, body_600898)

var listProvisioningArtifacts* = Call_ListProvisioningArtifacts_600884(
    name: "listProvisioningArtifacts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts",
    validator: validate_ListProvisioningArtifacts_600885, base: "/",
    url: url_ListProvisioningArtifacts_600886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifactsForServiceAction_600899 = ref object of OpenApiRestCall_599368
proc url_ListProvisioningArtifactsForServiceAction_600901(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisioningArtifactsForServiceAction_600900(path: JsonNode;
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
  var valid_600902 = query.getOrDefault("PageSize")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "PageSize", valid_600902
  var valid_600903 = query.getOrDefault("PageToken")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "PageToken", valid_600903
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
  var valid_600904 = header.getOrDefault("X-Amz-Date")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Date", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Security-Token")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Security-Token", valid_600905
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600906 = header.getOrDefault("X-Amz-Target")
  valid_600906 = validateParameter(valid_600906, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"))
  if valid_600906 != nil:
    section.add "X-Amz-Target", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Content-Sha256", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Algorithm")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Algorithm", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Signature")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Signature", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-SignedHeaders", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-Credential")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-Credential", valid_600911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_ListProvisioningArtifactsForServiceAction_600899;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600913, url, valid)

proc call*(call_600914: Call_ListProvisioningArtifactsForServiceAction_600899;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listProvisioningArtifactsForServiceAction
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600915 = newJObject()
  var body_600916 = newJObject()
  add(query_600915, "PageSize", newJString(PageSize))
  add(query_600915, "PageToken", newJString(PageToken))
  if body != nil:
    body_600916 = body
  result = call_600914.call(nil, query_600915, nil, nil, body_600916)

var listProvisioningArtifactsForServiceAction* = Call_ListProvisioningArtifactsForServiceAction_600899(
    name: "listProvisioningArtifactsForServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction",
    validator: validate_ListProvisioningArtifactsForServiceAction_600900,
    base: "/", url: url_ListProvisioningArtifactsForServiceAction_600901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecordHistory_600917 = ref object of OpenApiRestCall_599368
proc url_ListRecordHistory_600919(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRecordHistory_600918(path: JsonNode; query: JsonNode;
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
  var valid_600920 = header.getOrDefault("X-Amz-Date")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-Date", valid_600920
  var valid_600921 = header.getOrDefault("X-Amz-Security-Token")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-Security-Token", valid_600921
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600922 = header.getOrDefault("X-Amz-Target")
  valid_600922 = validateParameter(valid_600922, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListRecordHistory"))
  if valid_600922 != nil:
    section.add "X-Amz-Target", valid_600922
  var valid_600923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Content-Sha256", valid_600923
  var valid_600924 = header.getOrDefault("X-Amz-Algorithm")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-Algorithm", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Signature")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Signature", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-SignedHeaders", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-Credential")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Credential", valid_600927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600929: Call_ListRecordHistory_600917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified requests or all performed requests.
  ## 
  let valid = call_600929.validator(path, query, header, formData, body)
  let scheme = call_600929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600929.url(scheme.get, call_600929.host, call_600929.base,
                         call_600929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600929, url, valid)

proc call*(call_600930: Call_ListRecordHistory_600917; body: JsonNode): Recallable =
  ## listRecordHistory
  ## Lists the specified requests or all performed requests.
  ##   body: JObject (required)
  var body_600931 = newJObject()
  if body != nil:
    body_600931 = body
  result = call_600930.call(nil, nil, nil, nil, body_600931)

var listRecordHistory* = Call_ListRecordHistory_600917(name: "listRecordHistory",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory",
    validator: validate_ListRecordHistory_600918, base: "/",
    url: url_ListRecordHistory_600919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForTagOption_600932 = ref object of OpenApiRestCall_599368
proc url_ListResourcesForTagOption_600934(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourcesForTagOption_600933(path: JsonNode; query: JsonNode;
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
  var valid_600935 = query.getOrDefault("PageSize")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "PageSize", valid_600935
  var valid_600936 = query.getOrDefault("PageToken")
  valid_600936 = validateParameter(valid_600936, JString, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "PageToken", valid_600936
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
  var valid_600937 = header.getOrDefault("X-Amz-Date")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Date", valid_600937
  var valid_600938 = header.getOrDefault("X-Amz-Security-Token")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Security-Token", valid_600938
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600939 = header.getOrDefault("X-Amz-Target")
  valid_600939 = validateParameter(valid_600939, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListResourcesForTagOption"))
  if valid_600939 != nil:
    section.add "X-Amz-Target", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Content-Sha256", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-Algorithm")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-Algorithm", valid_600941
  var valid_600942 = header.getOrDefault("X-Amz-Signature")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "X-Amz-Signature", valid_600942
  var valid_600943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-SignedHeaders", valid_600943
  var valid_600944 = header.getOrDefault("X-Amz-Credential")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Credential", valid_600944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600946: Call_ListResourcesForTagOption_600932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources associated with the specified TagOption.
  ## 
  let valid = call_600946.validator(path, query, header, formData, body)
  let scheme = call_600946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600946.url(scheme.get, call_600946.host, call_600946.base,
                         call_600946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600946, url, valid)

proc call*(call_600947: Call_ListResourcesForTagOption_600932; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listResourcesForTagOption
  ## Lists the resources associated with the specified TagOption.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600948 = newJObject()
  var body_600949 = newJObject()
  add(query_600948, "PageSize", newJString(PageSize))
  add(query_600948, "PageToken", newJString(PageToken))
  if body != nil:
    body_600949 = body
  result = call_600947.call(nil, query_600948, nil, nil, body_600949)

var listResourcesForTagOption* = Call_ListResourcesForTagOption_600932(
    name: "listResourcesForTagOption", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption",
    validator: validate_ListResourcesForTagOption_600933, base: "/",
    url: url_ListResourcesForTagOption_600934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActions_600950 = ref object of OpenApiRestCall_599368
proc url_ListServiceActions_600952(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceActions_600951(path: JsonNode; query: JsonNode;
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
  var valid_600953 = query.getOrDefault("PageSize")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "PageSize", valid_600953
  var valid_600954 = query.getOrDefault("PageToken")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "PageToken", valid_600954
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
  var valid_600955 = header.getOrDefault("X-Amz-Date")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Date", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-Security-Token")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-Security-Token", valid_600956
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600957 = header.getOrDefault("X-Amz-Target")
  valid_600957 = validateParameter(valid_600957, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActions"))
  if valid_600957 != nil:
    section.add "X-Amz-Target", valid_600957
  var valid_600958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "X-Amz-Content-Sha256", valid_600958
  var valid_600959 = header.getOrDefault("X-Amz-Algorithm")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "X-Amz-Algorithm", valid_600959
  var valid_600960 = header.getOrDefault("X-Amz-Signature")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "X-Amz-Signature", valid_600960
  var valid_600961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600961 = validateParameter(valid_600961, JString, required = false,
                                 default = nil)
  if valid_600961 != nil:
    section.add "X-Amz-SignedHeaders", valid_600961
  var valid_600962 = header.getOrDefault("X-Amz-Credential")
  valid_600962 = validateParameter(valid_600962, JString, required = false,
                                 default = nil)
  if valid_600962 != nil:
    section.add "X-Amz-Credential", valid_600962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600964: Call_ListServiceActions_600950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all self-service actions.
  ## 
  let valid = call_600964.validator(path, query, header, formData, body)
  let scheme = call_600964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600964.url(scheme.get, call_600964.host, call_600964.base,
                         call_600964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600964, url, valid)

proc call*(call_600965: Call_ListServiceActions_600950; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActions
  ## Lists all self-service actions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600966 = newJObject()
  var body_600967 = newJObject()
  add(query_600966, "PageSize", newJString(PageSize))
  add(query_600966, "PageToken", newJString(PageToken))
  if body != nil:
    body_600967 = body
  result = call_600965.call(nil, query_600966, nil, nil, body_600967)

var listServiceActions* = Call_ListServiceActions_600950(
    name: "listServiceActions", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions",
    validator: validate_ListServiceActions_600951, base: "/",
    url: url_ListServiceActions_600952, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActionsForProvisioningArtifact_600968 = ref object of OpenApiRestCall_599368
proc url_ListServiceActionsForProvisioningArtifact_600970(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceActionsForProvisioningArtifact_600969(path: JsonNode;
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
  var valid_600971 = query.getOrDefault("PageSize")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "PageSize", valid_600971
  var valid_600972 = query.getOrDefault("PageToken")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "PageToken", valid_600972
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
  var valid_600973 = header.getOrDefault("X-Amz-Date")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "X-Amz-Date", valid_600973
  var valid_600974 = header.getOrDefault("X-Amz-Security-Token")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-Security-Token", valid_600974
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600975 = header.getOrDefault("X-Amz-Target")
  valid_600975 = validateParameter(valid_600975, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"))
  if valid_600975 != nil:
    section.add "X-Amz-Target", valid_600975
  var valid_600976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600976 = validateParameter(valid_600976, JString, required = false,
                                 default = nil)
  if valid_600976 != nil:
    section.add "X-Amz-Content-Sha256", valid_600976
  var valid_600977 = header.getOrDefault("X-Amz-Algorithm")
  valid_600977 = validateParameter(valid_600977, JString, required = false,
                                 default = nil)
  if valid_600977 != nil:
    section.add "X-Amz-Algorithm", valid_600977
  var valid_600978 = header.getOrDefault("X-Amz-Signature")
  valid_600978 = validateParameter(valid_600978, JString, required = false,
                                 default = nil)
  if valid_600978 != nil:
    section.add "X-Amz-Signature", valid_600978
  var valid_600979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "X-Amz-SignedHeaders", valid_600979
  var valid_600980 = header.getOrDefault("X-Amz-Credential")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-Credential", valid_600980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600982: Call_ListServiceActionsForProvisioningArtifact_600968;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  let valid = call_600982.validator(path, query, header, formData, body)
  let scheme = call_600982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600982.url(scheme.get, call_600982.host, call_600982.base,
                         call_600982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600982, url, valid)

proc call*(call_600983: Call_ListServiceActionsForProvisioningArtifact_600968;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActionsForProvisioningArtifact
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600984 = newJObject()
  var body_600985 = newJObject()
  add(query_600984, "PageSize", newJString(PageSize))
  add(query_600984, "PageToken", newJString(PageToken))
  if body != nil:
    body_600985 = body
  result = call_600983.call(nil, query_600984, nil, nil, body_600985)

var listServiceActionsForProvisioningArtifact* = Call_ListServiceActionsForProvisioningArtifact_600968(
    name: "listServiceActionsForProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact",
    validator: validate_ListServiceActionsForProvisioningArtifact_600969,
    base: "/", url: url_ListServiceActionsForProvisioningArtifact_600970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStackInstancesForProvisionedProduct_600986 = ref object of OpenApiRestCall_599368
proc url_ListStackInstancesForProvisionedProduct_600988(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStackInstancesForProvisionedProduct_600987(path: JsonNode;
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
  var valid_600989 = header.getOrDefault("X-Amz-Date")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "X-Amz-Date", valid_600989
  var valid_600990 = header.getOrDefault("X-Amz-Security-Token")
  valid_600990 = validateParameter(valid_600990, JString, required = false,
                                 default = nil)
  if valid_600990 != nil:
    section.add "X-Amz-Security-Token", valid_600990
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600991 = header.getOrDefault("X-Amz-Target")
  valid_600991 = validateParameter(valid_600991, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"))
  if valid_600991 != nil:
    section.add "X-Amz-Target", valid_600991
  var valid_600992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600992 = validateParameter(valid_600992, JString, required = false,
                                 default = nil)
  if valid_600992 != nil:
    section.add "X-Amz-Content-Sha256", valid_600992
  var valid_600993 = header.getOrDefault("X-Amz-Algorithm")
  valid_600993 = validateParameter(valid_600993, JString, required = false,
                                 default = nil)
  if valid_600993 != nil:
    section.add "X-Amz-Algorithm", valid_600993
  var valid_600994 = header.getOrDefault("X-Amz-Signature")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "X-Amz-Signature", valid_600994
  var valid_600995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600995 = validateParameter(valid_600995, JString, required = false,
                                 default = nil)
  if valid_600995 != nil:
    section.add "X-Amz-SignedHeaders", valid_600995
  var valid_600996 = header.getOrDefault("X-Amz-Credential")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "X-Amz-Credential", valid_600996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600998: Call_ListStackInstancesForProvisionedProduct_600986;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ## 
  let valid = call_600998.validator(path, query, header, formData, body)
  let scheme = call_600998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600998.url(scheme.get, call_600998.host, call_600998.base,
                         call_600998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600998, url, valid)

proc call*(call_600999: Call_ListStackInstancesForProvisionedProduct_600986;
          body: JsonNode): Recallable =
  ## listStackInstancesForProvisionedProduct
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ##   body: JObject (required)
  var body_601000 = newJObject()
  if body != nil:
    body_601000 = body
  result = call_600999.call(nil, nil, nil, nil, body_601000)

var listStackInstancesForProvisionedProduct* = Call_ListStackInstancesForProvisionedProduct_600986(
    name: "listStackInstancesForProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct",
    validator: validate_ListStackInstancesForProvisionedProduct_600987, base: "/",
    url: url_ListStackInstancesForProvisionedProduct_600988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagOptions_601001 = ref object of OpenApiRestCall_599368
proc url_ListTagOptions_601003(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagOptions_601002(path: JsonNode; query: JsonNode;
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
  var valid_601004 = query.getOrDefault("PageSize")
  valid_601004 = validateParameter(valid_601004, JString, required = false,
                                 default = nil)
  if valid_601004 != nil:
    section.add "PageSize", valid_601004
  var valid_601005 = query.getOrDefault("PageToken")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "PageToken", valid_601005
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
  var valid_601006 = header.getOrDefault("X-Amz-Date")
  valid_601006 = validateParameter(valid_601006, JString, required = false,
                                 default = nil)
  if valid_601006 != nil:
    section.add "X-Amz-Date", valid_601006
  var valid_601007 = header.getOrDefault("X-Amz-Security-Token")
  valid_601007 = validateParameter(valid_601007, JString, required = false,
                                 default = nil)
  if valid_601007 != nil:
    section.add "X-Amz-Security-Token", valid_601007
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601008 = header.getOrDefault("X-Amz-Target")
  valid_601008 = validateParameter(valid_601008, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListTagOptions"))
  if valid_601008 != nil:
    section.add "X-Amz-Target", valid_601008
  var valid_601009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Content-Sha256", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-Algorithm")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Algorithm", valid_601010
  var valid_601011 = header.getOrDefault("X-Amz-Signature")
  valid_601011 = validateParameter(valid_601011, JString, required = false,
                                 default = nil)
  if valid_601011 != nil:
    section.add "X-Amz-Signature", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-SignedHeaders", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Credential")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Credential", valid_601013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601015: Call_ListTagOptions_601001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  let valid = call_601015.validator(path, query, header, formData, body)
  let scheme = call_601015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601015.url(scheme.get, call_601015.host, call_601015.base,
                         call_601015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601015, url, valid)

proc call*(call_601016: Call_ListTagOptions_601001; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listTagOptions
  ## Lists the specified TagOptions or all TagOptions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601017 = newJObject()
  var body_601018 = newJObject()
  add(query_601017, "PageSize", newJString(PageSize))
  add(query_601017, "PageToken", newJString(PageToken))
  if body != nil:
    body_601018 = body
  result = call_601016.call(nil, query_601017, nil, nil, body_601018)

var listTagOptions* = Call_ListTagOptions_601001(name: "listTagOptions",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions",
    validator: validate_ListTagOptions_601002, base: "/", url: url_ListTagOptions_601003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ProvisionProduct_601019 = ref object of OpenApiRestCall_599368
proc url_ProvisionProduct_601021(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ProvisionProduct_601020(path: JsonNode; query: JsonNode;
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
  var valid_601022 = header.getOrDefault("X-Amz-Date")
  valid_601022 = validateParameter(valid_601022, JString, required = false,
                                 default = nil)
  if valid_601022 != nil:
    section.add "X-Amz-Date", valid_601022
  var valid_601023 = header.getOrDefault("X-Amz-Security-Token")
  valid_601023 = validateParameter(valid_601023, JString, required = false,
                                 default = nil)
  if valid_601023 != nil:
    section.add "X-Amz-Security-Token", valid_601023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601024 = header.getOrDefault("X-Amz-Target")
  valid_601024 = validateParameter(valid_601024, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ProvisionProduct"))
  if valid_601024 != nil:
    section.add "X-Amz-Target", valid_601024
  var valid_601025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Content-Sha256", valid_601025
  var valid_601026 = header.getOrDefault("X-Amz-Algorithm")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Algorithm", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Signature")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Signature", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-SignedHeaders", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Credential")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Credential", valid_601029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601031: Call_ProvisionProduct_601019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ## 
  let valid = call_601031.validator(path, query, header, formData, body)
  let scheme = call_601031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601031.url(scheme.get, call_601031.host, call_601031.base,
                         call_601031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601031, url, valid)

proc call*(call_601032: Call_ProvisionProduct_601019; body: JsonNode): Recallable =
  ## provisionProduct
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ##   body: JObject (required)
  var body_601033 = newJObject()
  if body != nil:
    body_601033 = body
  result = call_601032.call(nil, nil, nil, nil, body_601033)

var provisionProduct* = Call_ProvisionProduct_601019(name: "provisionProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct",
    validator: validate_ProvisionProduct_601020, base: "/",
    url: url_ProvisionProduct_601021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectPortfolioShare_601034 = ref object of OpenApiRestCall_599368
proc url_RejectPortfolioShare_601036(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectPortfolioShare_601035(path: JsonNode; query: JsonNode;
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
  var valid_601037 = header.getOrDefault("X-Amz-Date")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Date", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Security-Token")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Security-Token", valid_601038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601039 = header.getOrDefault("X-Amz-Target")
  valid_601039 = validateParameter(valid_601039, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.RejectPortfolioShare"))
  if valid_601039 != nil:
    section.add "X-Amz-Target", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Content-Sha256", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Algorithm")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Algorithm", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Signature")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Signature", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-SignedHeaders", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Credential")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Credential", valid_601044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601046: Call_RejectPortfolioShare_601034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an offer to share the specified portfolio.
  ## 
  let valid = call_601046.validator(path, query, header, formData, body)
  let scheme = call_601046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601046.url(scheme.get, call_601046.host, call_601046.base,
                         call_601046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601046, url, valid)

proc call*(call_601047: Call_RejectPortfolioShare_601034; body: JsonNode): Recallable =
  ## rejectPortfolioShare
  ## Rejects an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_601048 = newJObject()
  if body != nil:
    body_601048 = body
  result = call_601047.call(nil, nil, nil, nil, body_601048)

var rejectPortfolioShare* = Call_RejectPortfolioShare_601034(
    name: "rejectPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare",
    validator: validate_RejectPortfolioShare_601035, base: "/",
    url: url_RejectPortfolioShare_601036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScanProvisionedProducts_601049 = ref object of OpenApiRestCall_599368
proc url_ScanProvisionedProducts_601051(protocol: Scheme; host: string; base: string;
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

proc validate_ScanProvisionedProducts_601050(path: JsonNode; query: JsonNode;
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
  var valid_601052 = header.getOrDefault("X-Amz-Date")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Date", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Security-Token")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Security-Token", valid_601053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601054 = header.getOrDefault("X-Amz-Target")
  valid_601054 = validateParameter(valid_601054, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ScanProvisionedProducts"))
  if valid_601054 != nil:
    section.add "X-Amz-Target", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Content-Sha256", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Algorithm")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Algorithm", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Signature")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Signature", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-SignedHeaders", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Credential")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Credential", valid_601059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601061: Call_ScanProvisionedProducts_601049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ## 
  let valid = call_601061.validator(path, query, header, formData, body)
  let scheme = call_601061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601061.url(scheme.get, call_601061.host, call_601061.base,
                         call_601061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601061, url, valid)

proc call*(call_601062: Call_ScanProvisionedProducts_601049; body: JsonNode): Recallable =
  ## scanProvisionedProducts
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ##   body: JObject (required)
  var body_601063 = newJObject()
  if body != nil:
    body_601063 = body
  result = call_601062.call(nil, nil, nil, nil, body_601063)

var scanProvisionedProducts* = Call_ScanProvisionedProducts_601049(
    name: "scanProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts",
    validator: validate_ScanProvisionedProducts_601050, base: "/",
    url: url_ScanProvisionedProducts_601051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProducts_601064 = ref object of OpenApiRestCall_599368
proc url_SearchProducts_601066(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProducts_601065(path: JsonNode; query: JsonNode;
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
  var valid_601067 = query.getOrDefault("PageSize")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "PageSize", valid_601067
  var valid_601068 = query.getOrDefault("PageToken")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "PageToken", valid_601068
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
  var valid_601069 = header.getOrDefault("X-Amz-Date")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Date", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Security-Token")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Security-Token", valid_601070
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601071 = header.getOrDefault("X-Amz-Target")
  valid_601071 = validateParameter(valid_601071, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProducts"))
  if valid_601071 != nil:
    section.add "X-Amz-Target", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Content-Sha256", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Algorithm")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Algorithm", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Signature")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Signature", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-SignedHeaders", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Credential")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Credential", valid_601076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601078: Call_SearchProducts_601064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products to which the caller has access.
  ## 
  let valid = call_601078.validator(path, query, header, formData, body)
  let scheme = call_601078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601078.url(scheme.get, call_601078.host, call_601078.base,
                         call_601078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601078, url, valid)

proc call*(call_601079: Call_SearchProducts_601064; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProducts
  ## Gets information about the products to which the caller has access.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601080 = newJObject()
  var body_601081 = newJObject()
  add(query_601080, "PageSize", newJString(PageSize))
  add(query_601080, "PageToken", newJString(PageToken))
  if body != nil:
    body_601081 = body
  result = call_601079.call(nil, query_601080, nil, nil, body_601081)

var searchProducts* = Call_SearchProducts_601064(name: "searchProducts",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts",
    validator: validate_SearchProducts_601065, base: "/", url: url_SearchProducts_601066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProductsAsAdmin_601082 = ref object of OpenApiRestCall_599368
proc url_SearchProductsAsAdmin_601084(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProductsAsAdmin_601083(path: JsonNode; query: JsonNode;
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
  var valid_601085 = query.getOrDefault("PageSize")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "PageSize", valid_601085
  var valid_601086 = query.getOrDefault("PageToken")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "PageToken", valid_601086
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
  var valid_601087 = header.getOrDefault("X-Amz-Date")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Date", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Security-Token")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Security-Token", valid_601088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601089 = header.getOrDefault("X-Amz-Target")
  valid_601089 = validateParameter(valid_601089, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProductsAsAdmin"))
  if valid_601089 != nil:
    section.add "X-Amz-Target", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Content-Sha256", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Algorithm")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Algorithm", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Signature")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Signature", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-SignedHeaders", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Credential")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Credential", valid_601094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601096: Call_SearchProductsAsAdmin_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  let valid = call_601096.validator(path, query, header, formData, body)
  let scheme = call_601096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601096.url(scheme.get, call_601096.host, call_601096.base,
                         call_601096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601096, url, valid)

proc call*(call_601097: Call_SearchProductsAsAdmin_601082; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProductsAsAdmin
  ## Gets information about the products for the specified portfolio or all products.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601098 = newJObject()
  var body_601099 = newJObject()
  add(query_601098, "PageSize", newJString(PageSize))
  add(query_601098, "PageToken", newJString(PageToken))
  if body != nil:
    body_601099 = body
  result = call_601097.call(nil, query_601098, nil, nil, body_601099)

var searchProductsAsAdmin* = Call_SearchProductsAsAdmin_601082(
    name: "searchProductsAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin",
    validator: validate_SearchProductsAsAdmin_601083, base: "/",
    url: url_SearchProductsAsAdmin_601084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProvisionedProducts_601100 = ref object of OpenApiRestCall_599368
proc url_SearchProvisionedProducts_601102(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProvisionedProducts_601101(path: JsonNode; query: JsonNode;
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
  var valid_601103 = query.getOrDefault("PageSize")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "PageSize", valid_601103
  var valid_601104 = query.getOrDefault("PageToken")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "PageToken", valid_601104
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
  var valid_601105 = header.getOrDefault("X-Amz-Date")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Date", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Security-Token")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Security-Token", valid_601106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601107 = header.getOrDefault("X-Amz-Target")
  valid_601107 = validateParameter(valid_601107, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProvisionedProducts"))
  if valid_601107 != nil:
    section.add "X-Amz-Target", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Content-Sha256", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Algorithm")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Algorithm", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Signature")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Signature", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-SignedHeaders", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Credential")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Credential", valid_601112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601114: Call_SearchProvisionedProducts_601100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  let valid = call_601114.validator(path, query, header, formData, body)
  let scheme = call_601114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601114.url(scheme.get, call_601114.host, call_601114.base,
                         call_601114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601114, url, valid)

proc call*(call_601115: Call_SearchProvisionedProducts_601100; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProvisionedProducts
  ## Gets information about the provisioned products that meet the specified criteria.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601116 = newJObject()
  var body_601117 = newJObject()
  add(query_601116, "PageSize", newJString(PageSize))
  add(query_601116, "PageToken", newJString(PageToken))
  if body != nil:
    body_601117 = body
  result = call_601115.call(nil, query_601116, nil, nil, body_601117)

var searchProvisionedProducts* = Call_SearchProvisionedProducts_601100(
    name: "searchProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts",
    validator: validate_SearchProvisionedProducts_601101, base: "/",
    url: url_SearchProvisionedProducts_601102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateProvisionedProduct_601118 = ref object of OpenApiRestCall_599368
proc url_TerminateProvisionedProduct_601120(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateProvisionedProduct_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = header.getOrDefault("X-Amz-Date")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Date", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Security-Token")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Security-Token", valid_601122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601123 = header.getOrDefault("X-Amz-Target")
  valid_601123 = validateParameter(valid_601123, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.TerminateProvisionedProduct"))
  if valid_601123 != nil:
    section.add "X-Amz-Target", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Content-Sha256", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Algorithm")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Algorithm", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Signature")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Signature", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-SignedHeaders", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_TerminateProvisionedProduct_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601130, url, valid)

proc call*(call_601131: Call_TerminateProvisionedProduct_601118; body: JsonNode): Recallable =
  ## terminateProvisionedProduct
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_601132 = newJObject()
  if body != nil:
    body_601132 = body
  result = call_601131.call(nil, nil, nil, nil, body_601132)

var terminateProvisionedProduct* = Call_TerminateProvisionedProduct_601118(
    name: "terminateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct",
    validator: validate_TerminateProvisionedProduct_601119, base: "/",
    url: url_TerminateProvisionedProduct_601120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConstraint_601133 = ref object of OpenApiRestCall_599368
proc url_UpdateConstraint_601135(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConstraint_601134(path: JsonNode; query: JsonNode;
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
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601138 = header.getOrDefault("X-Amz-Target")
  valid_601138 = validateParameter(valid_601138, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateConstraint"))
  if valid_601138 != nil:
    section.add "X-Amz-Target", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_UpdateConstraint_601133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified constraint.
  ## 
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601145, url, valid)

proc call*(call_601146: Call_UpdateConstraint_601133; body: JsonNode): Recallable =
  ## updateConstraint
  ## Updates the specified constraint.
  ##   body: JObject (required)
  var body_601147 = newJObject()
  if body != nil:
    body_601147 = body
  result = call_601146.call(nil, nil, nil, nil, body_601147)

var updateConstraint* = Call_UpdateConstraint_601133(name: "updateConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint",
    validator: validate_UpdateConstraint_601134, base: "/",
    url: url_UpdateConstraint_601135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePortfolio_601148 = ref object of OpenApiRestCall_599368
proc url_UpdatePortfolio_601150(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePortfolio_601149(path: JsonNode; query: JsonNode;
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
  var valid_601151 = header.getOrDefault("X-Amz-Date")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Date", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Security-Token")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Security-Token", valid_601152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601153 = header.getOrDefault("X-Amz-Target")
  valid_601153 = validateParameter(valid_601153, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdatePortfolio"))
  if valid_601153 != nil:
    section.add "X-Amz-Target", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_UpdatePortfolio_601148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601160, url, valid)

proc call*(call_601161: Call_UpdatePortfolio_601148; body: JsonNode): Recallable =
  ## updatePortfolio
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var updatePortfolio* = Call_UpdatePortfolio_601148(name: "updatePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio",
    validator: validate_UpdatePortfolio_601149, base: "/", url: url_UpdatePortfolio_601150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProduct_601163 = ref object of OpenApiRestCall_599368
proc url_UpdateProduct_601165(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProduct_601164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601168 = header.getOrDefault("X-Amz-Target")
  valid_601168 = validateParameter(valid_601168, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProduct"))
  if valid_601168 != nil:
    section.add "X-Amz-Target", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Content-Sha256", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Algorithm")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Algorithm", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Signature")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Signature", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-SignedHeaders", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Credential")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Credential", valid_601173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601175: Call_UpdateProduct_601163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified product.
  ## 
  let valid = call_601175.validator(path, query, header, formData, body)
  let scheme = call_601175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601175.url(scheme.get, call_601175.host, call_601175.base,
                         call_601175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601175, url, valid)

proc call*(call_601176: Call_UpdateProduct_601163; body: JsonNode): Recallable =
  ## updateProduct
  ## Updates the specified product.
  ##   body: JObject (required)
  var body_601177 = newJObject()
  if body != nil:
    body_601177 = body
  result = call_601176.call(nil, nil, nil, nil, body_601177)

var updateProduct* = Call_UpdateProduct_601163(name: "updateProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct",
    validator: validate_UpdateProduct_601164, base: "/", url: url_UpdateProduct_601165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProduct_601178 = ref object of OpenApiRestCall_599368
proc url_UpdateProvisionedProduct_601180(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisionedProduct_601179(path: JsonNode; query: JsonNode;
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
  var valid_601181 = header.getOrDefault("X-Amz-Date")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Date", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Security-Token")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Security-Token", valid_601182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601183 = header.getOrDefault("X-Amz-Target")
  valid_601183 = validateParameter(valid_601183, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProduct"))
  if valid_601183 != nil:
    section.add "X-Amz-Target", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601190: Call_UpdateProvisionedProduct_601178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_601190.validator(path, query, header, formData, body)
  let scheme = call_601190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601190.url(scheme.get, call_601190.host, call_601190.base,
                         call_601190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601190, url, valid)

proc call*(call_601191: Call_UpdateProvisionedProduct_601178; body: JsonNode): Recallable =
  ## updateProvisionedProduct
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_601192 = newJObject()
  if body != nil:
    body_601192 = body
  result = call_601191.call(nil, nil, nil, nil, body_601192)

var updateProvisionedProduct* = Call_UpdateProvisionedProduct_601178(
    name: "updateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct",
    validator: validate_UpdateProvisionedProduct_601179, base: "/",
    url: url_UpdateProvisionedProduct_601180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProductProperties_601193 = ref object of OpenApiRestCall_599368
proc url_UpdateProvisionedProductProperties_601195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisionedProductProperties_601194(path: JsonNode;
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
  var valid_601196 = header.getOrDefault("X-Amz-Date")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Date", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Security-Token")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Security-Token", valid_601197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601198 = header.getOrDefault("X-Amz-Target")
  valid_601198 = validateParameter(valid_601198, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProductProperties"))
  if valid_601198 != nil:
    section.add "X-Amz-Target", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601205: Call_UpdateProvisionedProductProperties_601193;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests updates to the properties of the specified provisioned product.
  ## 
  let valid = call_601205.validator(path, query, header, formData, body)
  let scheme = call_601205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601205.url(scheme.get, call_601205.host, call_601205.base,
                         call_601205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601205, url, valid)

proc call*(call_601206: Call_UpdateProvisionedProductProperties_601193;
          body: JsonNode): Recallable =
  ## updateProvisionedProductProperties
  ## Requests updates to the properties of the specified provisioned product.
  ##   body: JObject (required)
  var body_601207 = newJObject()
  if body != nil:
    body_601207 = body
  result = call_601206.call(nil, nil, nil, nil, body_601207)

var updateProvisionedProductProperties* = Call_UpdateProvisionedProductProperties_601193(
    name: "updateProvisionedProductProperties", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties",
    validator: validate_UpdateProvisionedProductProperties_601194, base: "/",
    url: url_UpdateProvisionedProductProperties_601195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisioningArtifact_601208 = ref object of OpenApiRestCall_599368
proc url_UpdateProvisioningArtifact_601210(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisioningArtifact_601209(path: JsonNode; query: JsonNode;
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
  var valid_601211 = header.getOrDefault("X-Amz-Date")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Date", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Security-Token")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Security-Token", valid_601212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601213 = header.getOrDefault("X-Amz-Target")
  valid_601213 = validateParameter(valid_601213, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisioningArtifact"))
  if valid_601213 != nil:
    section.add "X-Amz-Target", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Content-Sha256", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Algorithm")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Algorithm", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Signature")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Signature", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-SignedHeaders", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Credential")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Credential", valid_601218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601220: Call_UpdateProvisioningArtifact_601208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_601220.validator(path, query, header, formData, body)
  let scheme = call_601220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601220.url(scheme.get, call_601220.host, call_601220.base,
                         call_601220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601220, url, valid)

proc call*(call_601221: Call_UpdateProvisioningArtifact_601208; body: JsonNode): Recallable =
  ## updateProvisioningArtifact
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_601222 = newJObject()
  if body != nil:
    body_601222 = body
  result = call_601221.call(nil, nil, nil, nil, body_601222)

var updateProvisioningArtifact* = Call_UpdateProvisioningArtifact_601208(
    name: "updateProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact",
    validator: validate_UpdateProvisioningArtifact_601209, base: "/",
    url: url_UpdateProvisioningArtifact_601210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceAction_601223 = ref object of OpenApiRestCall_599368
proc url_UpdateServiceAction_601225(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServiceAction_601224(path: JsonNode; query: JsonNode;
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
  var valid_601226 = header.getOrDefault("X-Amz-Date")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Date", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Security-Token")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Security-Token", valid_601227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601228 = header.getOrDefault("X-Amz-Target")
  valid_601228 = validateParameter(valid_601228, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateServiceAction"))
  if valid_601228 != nil:
    section.add "X-Amz-Target", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Content-Sha256", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Algorithm")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Algorithm", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Signature")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Signature", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-SignedHeaders", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Credential")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Credential", valid_601233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_UpdateServiceAction_601223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a self-service action.
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601235, url, valid)

proc call*(call_601236: Call_UpdateServiceAction_601223; body: JsonNode): Recallable =
  ## updateServiceAction
  ## Updates a self-service action.
  ##   body: JObject (required)
  var body_601237 = newJObject()
  if body != nil:
    body_601237 = body
  result = call_601236.call(nil, nil, nil, nil, body_601237)

var updateServiceAction* = Call_UpdateServiceAction_601223(
    name: "updateServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction",
    validator: validate_UpdateServiceAction_601224, base: "/",
    url: url_UpdateServiceAction_601225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagOption_601238 = ref object of OpenApiRestCall_599368
proc url_UpdateTagOption_601240(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTagOption_601239(path: JsonNode; query: JsonNode;
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
  var valid_601241 = header.getOrDefault("X-Amz-Date")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Date", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Security-Token")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Security-Token", valid_601242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601243 = header.getOrDefault("X-Amz-Target")
  valid_601243 = validateParameter(valid_601243, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateTagOption"))
  if valid_601243 != nil:
    section.add "X-Amz-Target", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Content-Sha256", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Algorithm")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Algorithm", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Signature")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Signature", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-SignedHeaders", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Credential")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Credential", valid_601248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601250: Call_UpdateTagOption_601238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified TagOption.
  ## 
  let valid = call_601250.validator(path, query, header, formData, body)
  let scheme = call_601250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601250.url(scheme.get, call_601250.host, call_601250.base,
                         call_601250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601250, url, valid)

proc call*(call_601251: Call_UpdateTagOption_601238; body: JsonNode): Recallable =
  ## updateTagOption
  ## Updates the specified TagOption.
  ##   body: JObject (required)
  var body_601252 = newJObject()
  if body != nil:
    body_601252 = body
  result = call_601251.call(nil, nil, nil, nil, body_601252)

var updateTagOption* = Call_UpdateTagOption_601238(name: "updateTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption",
    validator: validate_UpdateTagOption_601239, base: "/", url: url_UpdateTagOption_601240,
    schemes: {Scheme.Https, Scheme.Http})
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
