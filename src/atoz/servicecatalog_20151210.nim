
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptPortfolioShare_592703 = ref object of OpenApiRestCall_592364
proc url_AcceptPortfolioShare_592705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcceptPortfolioShare_592704(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592830 = header.getOrDefault("X-Amz-Target")
  valid_592830 = validateParameter(valid_592830, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AcceptPortfolioShare"))
  if valid_592830 != nil:
    section.add "X-Amz-Target", valid_592830
  var valid_592831 = header.getOrDefault("X-Amz-Signature")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = nil)
  if valid_592831 != nil:
    section.add "X-Amz-Signature", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Content-Sha256", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Date")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Date", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Credential")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Credential", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Security-Token")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Security-Token", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Algorithm")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Algorithm", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-SignedHeaders", valid_592837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_AcceptPortfolioShare_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an offer to share the specified portfolio.
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_AcceptPortfolioShare_592703; body: JsonNode): Recallable =
  ## acceptPortfolioShare
  ## Accepts an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_592933 = newJObject()
  if body != nil:
    body_592933 = body
  result = call_592932.call(nil, nil, nil, nil, body_592933)

var acceptPortfolioShare* = Call_AcceptPortfolioShare_592703(
    name: "acceptPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare",
    validator: validate_AcceptPortfolioShare_592704, base: "/",
    url: url_AcceptPortfolioShare_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateBudgetWithResource_592972 = ref object of OpenApiRestCall_592364
proc url_AssociateBudgetWithResource_592974(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateBudgetWithResource_592973(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592975 = header.getOrDefault("X-Amz-Target")
  valid_592975 = validateParameter(valid_592975, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateBudgetWithResource"))
  if valid_592975 != nil:
    section.add "X-Amz-Target", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Signature", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Content-Sha256", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Date")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Date", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Credential")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Credential", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Security-Token")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Security-Token", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Algorithm")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Algorithm", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-SignedHeaders", valid_592982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_AssociateBudgetWithResource_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified budget with the specified resource.
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_AssociateBudgetWithResource_592972; body: JsonNode): Recallable =
  ## associateBudgetWithResource
  ## Associates the specified budget with the specified resource.
  ##   body: JObject (required)
  var body_592986 = newJObject()
  if body != nil:
    body_592986 = body
  result = call_592985.call(nil, nil, nil, nil, body_592986)

var associateBudgetWithResource* = Call_AssociateBudgetWithResource_592972(
    name: "associateBudgetWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource",
    validator: validate_AssociateBudgetWithResource_592973, base: "/",
    url: url_AssociateBudgetWithResource_592974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePrincipalWithPortfolio_592987 = ref object of OpenApiRestCall_592364
proc url_AssociatePrincipalWithPortfolio_592989(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociatePrincipalWithPortfolio_592988(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592990 = header.getOrDefault("X-Amz-Target")
  valid_592990 = validateParameter(valid_592990, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"))
  if valid_592990 != nil:
    section.add "X-Amz-Target", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592999: Call_AssociatePrincipalWithPortfolio_592987;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified principal ARN with the specified portfolio.
  ## 
  let valid = call_592999.validator(path, query, header, formData, body)
  let scheme = call_592999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592999.url(scheme.get, call_592999.host, call_592999.base,
                         call_592999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592999, url, valid)

proc call*(call_593000: Call_AssociatePrincipalWithPortfolio_592987; body: JsonNode): Recallable =
  ## associatePrincipalWithPortfolio
  ## Associates the specified principal ARN with the specified portfolio.
  ##   body: JObject (required)
  var body_593001 = newJObject()
  if body != nil:
    body_593001 = body
  result = call_593000.call(nil, nil, nil, nil, body_593001)

var associatePrincipalWithPortfolio* = Call_AssociatePrincipalWithPortfolio_592987(
    name: "associatePrincipalWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio",
    validator: validate_AssociatePrincipalWithPortfolio_592988, base: "/",
    url: url_AssociatePrincipalWithPortfolio_592989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateProductWithPortfolio_593002 = ref object of OpenApiRestCall_592364
proc url_AssociateProductWithPortfolio_593004(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateProductWithPortfolio_593003(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593005 = header.getOrDefault("X-Amz-Target")
  valid_593005 = validateParameter(valid_593005, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateProductWithPortfolio"))
  if valid_593005 != nil:
    section.add "X-Amz-Target", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Signature")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Signature", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Content-Sha256", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Date")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Date", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Credential")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Credential", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Security-Token")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Security-Token", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Algorithm")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Algorithm", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-SignedHeaders", valid_593012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593014: Call_AssociateProductWithPortfolio_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified product with the specified portfolio.
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_AssociateProductWithPortfolio_593002; body: JsonNode): Recallable =
  ## associateProductWithPortfolio
  ## Associates the specified product with the specified portfolio.
  ##   body: JObject (required)
  var body_593016 = newJObject()
  if body != nil:
    body_593016 = body
  result = call_593015.call(nil, nil, nil, nil, body_593016)

var associateProductWithPortfolio* = Call_AssociateProductWithPortfolio_593002(
    name: "associateProductWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio",
    validator: validate_AssociateProductWithPortfolio_593003, base: "/",
    url: url_AssociateProductWithPortfolio_593004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceActionWithProvisioningArtifact_593017 = ref object of OpenApiRestCall_592364
proc url_AssociateServiceActionWithProvisioningArtifact_593019(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateServiceActionWithProvisioningArtifact_593018(
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593020 = header.getOrDefault("X-Amz-Target")
  valid_593020 = validateParameter(valid_593020, JString, required = true, default = newJString("AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"))
  if valid_593020 != nil:
    section.add "X-Amz-Target", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Signature", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Content-Sha256", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Date", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Credential")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Credential", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Security-Token")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Security-Token", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Algorithm")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Algorithm", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-SignedHeaders", valid_593027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_AssociateServiceActionWithProvisioningArtifact_593017;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a self-service action with a provisioning artifact.
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_AssociateServiceActionWithProvisioningArtifact_593017;
          body: JsonNode): Recallable =
  ## associateServiceActionWithProvisioningArtifact
  ## Associates a self-service action with a provisioning artifact.
  ##   body: JObject (required)
  var body_593031 = newJObject()
  if body != nil:
    body_593031 = body
  result = call_593030.call(nil, nil, nil, nil, body_593031)

var associateServiceActionWithProvisioningArtifact* = Call_AssociateServiceActionWithProvisioningArtifact_593017(
    name: "associateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact",
    validator: validate_AssociateServiceActionWithProvisioningArtifact_593018,
    base: "/", url: url_AssociateServiceActionWithProvisioningArtifact_593019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTagOptionWithResource_593032 = ref object of OpenApiRestCall_592364
proc url_AssociateTagOptionWithResource_593034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateTagOptionWithResource_593033(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593035 = header.getOrDefault("X-Amz-Target")
  valid_593035 = validateParameter(valid_593035, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateTagOptionWithResource"))
  if valid_593035 != nil:
    section.add "X-Amz-Target", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Signature", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Content-Sha256", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Date")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Date", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Credential")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Credential", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Security-Token")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Security-Token", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Algorithm")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Algorithm", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-SignedHeaders", valid_593042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593044: Call_AssociateTagOptionWithResource_593032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associate the specified TagOption with the specified portfolio or product.
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_AssociateTagOptionWithResource_593032; body: JsonNode): Recallable =
  ## associateTagOptionWithResource
  ## Associate the specified TagOption with the specified portfolio or product.
  ##   body: JObject (required)
  var body_593046 = newJObject()
  if body != nil:
    body_593046 = body
  result = call_593045.call(nil, nil, nil, nil, body_593046)

var associateTagOptionWithResource* = Call_AssociateTagOptionWithResource_593032(
    name: "associateTagOptionWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource",
    validator: validate_AssociateTagOptionWithResource_593033, base: "/",
    url: url_AssociateTagOptionWithResource_593034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateServiceActionWithProvisioningArtifact_593047 = ref object of OpenApiRestCall_592364
proc url_BatchAssociateServiceActionWithProvisioningArtifact_593049(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchAssociateServiceActionWithProvisioningArtifact_593048(
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593050 = header.getOrDefault("X-Amz-Target")
  valid_593050 = validateParameter(valid_593050, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"))
  if valid_593050 != nil:
    section.add "X-Amz-Target", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Signature")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Signature", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Content-Sha256", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Date")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Date", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Credential")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Credential", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Security-Token")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Security-Token", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Algorithm")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Algorithm", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-SignedHeaders", valid_593057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_BatchAssociateServiceActionWithProvisioningArtifact_593047;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates multiple self-service actions with provisioning artifacts.
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_BatchAssociateServiceActionWithProvisioningArtifact_593047;
          body: JsonNode): Recallable =
  ## batchAssociateServiceActionWithProvisioningArtifact
  ## Associates multiple self-service actions with provisioning artifacts.
  ##   body: JObject (required)
  var body_593061 = newJObject()
  if body != nil:
    body_593061 = body
  result = call_593060.call(nil, nil, nil, nil, body_593061)

var batchAssociateServiceActionWithProvisioningArtifact* = Call_BatchAssociateServiceActionWithProvisioningArtifact_593047(
    name: "batchAssociateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact",
    validator: validate_BatchAssociateServiceActionWithProvisioningArtifact_593048,
    base: "/", url: url_BatchAssociateServiceActionWithProvisioningArtifact_593049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateServiceActionFromProvisioningArtifact_593062 = ref object of OpenApiRestCall_592364
proc url_BatchDisassociateServiceActionFromProvisioningArtifact_593064(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDisassociateServiceActionFromProvisioningArtifact_593063(
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593065 = header.getOrDefault("X-Amz-Target")
  valid_593065 = validateParameter(valid_593065, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"))
  if valid_593065 != nil:
    section.add "X-Amz-Target", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_BatchDisassociateServiceActionFromProvisioningArtifact_593062;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_BatchDisassociateServiceActionFromProvisioningArtifact_593062;
          body: JsonNode): Recallable =
  ## batchDisassociateServiceActionFromProvisioningArtifact
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_593076 = newJObject()
  if body != nil:
    body_593076 = body
  result = call_593075.call(nil, nil, nil, nil, body_593076)

var batchDisassociateServiceActionFromProvisioningArtifact* = Call_BatchDisassociateServiceActionFromProvisioningArtifact_593062(
    name: "batchDisassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact",
    validator: validate_BatchDisassociateServiceActionFromProvisioningArtifact_593063,
    base: "/", url: url_BatchDisassociateServiceActionFromProvisioningArtifact_593064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyProduct_593077 = ref object of OpenApiRestCall_592364
proc url_CopyProduct_593079(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CopyProduct_593078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593080 = header.getOrDefault("X-Amz-Target")
  valid_593080 = validateParameter(valid_593080, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CopyProduct"))
  if valid_593080 != nil:
    section.add "X-Amz-Target", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Signature")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Signature", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Content-Sha256", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Date")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Date", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Credential")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Credential", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Security-Token")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Security-Token", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Algorithm")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Algorithm", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-SignedHeaders", valid_593087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593089: Call_CopyProduct_593077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ## 
  let valid = call_593089.validator(path, query, header, formData, body)
  let scheme = call_593089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593089.url(scheme.get, call_593089.host, call_593089.base,
                         call_593089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593089, url, valid)

proc call*(call_593090: Call_CopyProduct_593077; body: JsonNode): Recallable =
  ## copyProduct
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ##   body: JObject (required)
  var body_593091 = newJObject()
  if body != nil:
    body_593091 = body
  result = call_593090.call(nil, nil, nil, nil, body_593091)

var copyProduct* = Call_CopyProduct_593077(name: "copyProduct",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct",
                                        validator: validate_CopyProduct_593078,
                                        base: "/", url: url_CopyProduct_593079,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConstraint_593092 = ref object of OpenApiRestCall_592364
proc url_CreateConstraint_593094(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConstraint_593093(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593095 = header.getOrDefault("X-Amz-Target")
  valid_593095 = validateParameter(valid_593095, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateConstraint"))
  if valid_593095 != nil:
    section.add "X-Amz-Target", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Signature")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Signature", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Content-Sha256", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Date")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Date", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Credential")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Credential", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Security-Token")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Security-Token", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Algorithm")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Algorithm", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-SignedHeaders", valid_593102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593104: Call_CreateConstraint_593092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a constraint.
  ## 
  let valid = call_593104.validator(path, query, header, formData, body)
  let scheme = call_593104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593104.url(scheme.get, call_593104.host, call_593104.base,
                         call_593104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593104, url, valid)

proc call*(call_593105: Call_CreateConstraint_593092; body: JsonNode): Recallable =
  ## createConstraint
  ## Creates a constraint.
  ##   body: JObject (required)
  var body_593106 = newJObject()
  if body != nil:
    body_593106 = body
  result = call_593105.call(nil, nil, nil, nil, body_593106)

var createConstraint* = Call_CreateConstraint_593092(name: "createConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint",
    validator: validate_CreateConstraint_593093, base: "/",
    url: url_CreateConstraint_593094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolio_593107 = ref object of OpenApiRestCall_592364
proc url_CreatePortfolio_593109(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePortfolio_593108(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593110 = header.getOrDefault("X-Amz-Target")
  valid_593110 = validateParameter(valid_593110, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolio"))
  if valid_593110 != nil:
    section.add "X-Amz-Target", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Signature")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Signature", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Content-Sha256", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Date")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Date", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Credential")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Credential", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Security-Token")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Security-Token", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Algorithm")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Algorithm", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-SignedHeaders", valid_593117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593119: Call_CreatePortfolio_593107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a portfolio.
  ## 
  let valid = call_593119.validator(path, query, header, formData, body)
  let scheme = call_593119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593119.url(scheme.get, call_593119.host, call_593119.base,
                         call_593119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593119, url, valid)

proc call*(call_593120: Call_CreatePortfolio_593107; body: JsonNode): Recallable =
  ## createPortfolio
  ## Creates a portfolio.
  ##   body: JObject (required)
  var body_593121 = newJObject()
  if body != nil:
    body_593121 = body
  result = call_593120.call(nil, nil, nil, nil, body_593121)

var createPortfolio* = Call_CreatePortfolio_593107(name: "createPortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio",
    validator: validate_CreatePortfolio_593108, base: "/", url: url_CreatePortfolio_593109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolioShare_593122 = ref object of OpenApiRestCall_592364
proc url_CreatePortfolioShare_593124(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePortfolioShare_593123(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593125 = header.getOrDefault("X-Amz-Target")
  valid_593125 = validateParameter(valid_593125, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolioShare"))
  if valid_593125 != nil:
    section.add "X-Amz-Target", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Signature")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Signature", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Content-Sha256", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Date")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Date", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Credential")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Credential", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Security-Token")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Security-Token", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Algorithm")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Algorithm", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-SignedHeaders", valid_593132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593134: Call_CreatePortfolioShare_593122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ## 
  let valid = call_593134.validator(path, query, header, formData, body)
  let scheme = call_593134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593134.url(scheme.get, call_593134.host, call_593134.base,
                         call_593134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593134, url, valid)

proc call*(call_593135: Call_CreatePortfolioShare_593122; body: JsonNode): Recallable =
  ## createPortfolioShare
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ##   body: JObject (required)
  var body_593136 = newJObject()
  if body != nil:
    body_593136 = body
  result = call_593135.call(nil, nil, nil, nil, body_593136)

var createPortfolioShare* = Call_CreatePortfolioShare_593122(
    name: "createPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare",
    validator: validate_CreatePortfolioShare_593123, base: "/",
    url: url_CreatePortfolioShare_593124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProduct_593137 = ref object of OpenApiRestCall_592364
proc url_CreateProduct_593139(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProduct_593138(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593140 = header.getOrDefault("X-Amz-Target")
  valid_593140 = validateParameter(valid_593140, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProduct"))
  if valid_593140 != nil:
    section.add "X-Amz-Target", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Signature")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Signature", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Content-Sha256", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Date")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Date", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Credential")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Credential", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Security-Token")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Security-Token", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Algorithm")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Algorithm", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-SignedHeaders", valid_593147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593149: Call_CreateProduct_593137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a product.
  ## 
  let valid = call_593149.validator(path, query, header, formData, body)
  let scheme = call_593149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593149.url(scheme.get, call_593149.host, call_593149.base,
                         call_593149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593149, url, valid)

proc call*(call_593150: Call_CreateProduct_593137; body: JsonNode): Recallable =
  ## createProduct
  ## Creates a product.
  ##   body: JObject (required)
  var body_593151 = newJObject()
  if body != nil:
    body_593151 = body
  result = call_593150.call(nil, nil, nil, nil, body_593151)

var createProduct* = Call_CreateProduct_593137(name: "createProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct",
    validator: validate_CreateProduct_593138, base: "/", url: url_CreateProduct_593139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisionedProductPlan_593152 = ref object of OpenApiRestCall_592364
proc url_CreateProvisionedProductPlan_593154(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProvisionedProductPlan_593153(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593155 = header.getOrDefault("X-Amz-Target")
  valid_593155 = validateParameter(valid_593155, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisionedProductPlan"))
  if valid_593155 != nil:
    section.add "X-Amz-Target", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Signature")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Signature", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Content-Sha256", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Date")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Date", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Credential")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Credential", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Security-Token")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Security-Token", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Algorithm")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Algorithm", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-SignedHeaders", valid_593162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593164: Call_CreateProvisionedProductPlan_593152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ## 
  let valid = call_593164.validator(path, query, header, formData, body)
  let scheme = call_593164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593164.url(scheme.get, call_593164.host, call_593164.base,
                         call_593164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593164, url, valid)

proc call*(call_593165: Call_CreateProvisionedProductPlan_593152; body: JsonNode): Recallable =
  ## createProvisionedProductPlan
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ##   body: JObject (required)
  var body_593166 = newJObject()
  if body != nil:
    body_593166 = body
  result = call_593165.call(nil, nil, nil, nil, body_593166)

var createProvisionedProductPlan* = Call_CreateProvisionedProductPlan_593152(
    name: "createProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan",
    validator: validate_CreateProvisionedProductPlan_593153, base: "/",
    url: url_CreateProvisionedProductPlan_593154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisioningArtifact_593167 = ref object of OpenApiRestCall_592364
proc url_CreateProvisioningArtifact_593169(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProvisioningArtifact_593168(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593170 = header.getOrDefault("X-Amz-Target")
  valid_593170 = validateParameter(valid_593170, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisioningArtifact"))
  if valid_593170 != nil:
    section.add "X-Amz-Target", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Signature")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Signature", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Content-Sha256", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Date")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Date", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Credential")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Credential", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Security-Token")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Security-Token", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Algorithm")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Algorithm", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-SignedHeaders", valid_593177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593179: Call_CreateProvisioningArtifact_593167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_CreateProvisioningArtifact_593167; body: JsonNode): Recallable =
  ## createProvisioningArtifact
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_593181 = newJObject()
  if body != nil:
    body_593181 = body
  result = call_593180.call(nil, nil, nil, nil, body_593181)

var createProvisioningArtifact* = Call_CreateProvisioningArtifact_593167(
    name: "createProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact",
    validator: validate_CreateProvisioningArtifact_593168, base: "/",
    url: url_CreateProvisioningArtifact_593169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServiceAction_593182 = ref object of OpenApiRestCall_592364
proc url_CreateServiceAction_593184(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateServiceAction_593183(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593185 = header.getOrDefault("X-Amz-Target")
  valid_593185 = validateParameter(valid_593185, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateServiceAction"))
  if valid_593185 != nil:
    section.add "X-Amz-Target", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Signature")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Signature", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Content-Sha256", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Date")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Date", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Credential")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Credential", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Security-Token")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Security-Token", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Algorithm")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Algorithm", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-SignedHeaders", valid_593192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593194: Call_CreateServiceAction_593182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a self-service action.
  ## 
  let valid = call_593194.validator(path, query, header, formData, body)
  let scheme = call_593194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593194.url(scheme.get, call_593194.host, call_593194.base,
                         call_593194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593194, url, valid)

proc call*(call_593195: Call_CreateServiceAction_593182; body: JsonNode): Recallable =
  ## createServiceAction
  ## Creates a self-service action.
  ##   body: JObject (required)
  var body_593196 = newJObject()
  if body != nil:
    body_593196 = body
  result = call_593195.call(nil, nil, nil, nil, body_593196)

var createServiceAction* = Call_CreateServiceAction_593182(
    name: "createServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction",
    validator: validate_CreateServiceAction_593183, base: "/",
    url: url_CreateServiceAction_593184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTagOption_593197 = ref object of OpenApiRestCall_592364
proc url_CreateTagOption_593199(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTagOption_593198(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593200 = header.getOrDefault("X-Amz-Target")
  valid_593200 = validateParameter(valid_593200, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateTagOption"))
  if valid_593200 != nil:
    section.add "X-Amz-Target", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Signature")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Signature", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Content-Sha256", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Date")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Date", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Credential")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Credential", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Security-Token")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Security-Token", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Algorithm")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Algorithm", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-SignedHeaders", valid_593207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593209: Call_CreateTagOption_593197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a TagOption.
  ## 
  let valid = call_593209.validator(path, query, header, formData, body)
  let scheme = call_593209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593209.url(scheme.get, call_593209.host, call_593209.base,
                         call_593209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593209, url, valid)

proc call*(call_593210: Call_CreateTagOption_593197; body: JsonNode): Recallable =
  ## createTagOption
  ## Creates a TagOption.
  ##   body: JObject (required)
  var body_593211 = newJObject()
  if body != nil:
    body_593211 = body
  result = call_593210.call(nil, nil, nil, nil, body_593211)

var createTagOption* = Call_CreateTagOption_593197(name: "createTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption",
    validator: validate_CreateTagOption_593198, base: "/", url: url_CreateTagOption_593199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConstraint_593212 = ref object of OpenApiRestCall_592364
proc url_DeleteConstraint_593214(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConstraint_593213(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593215 = header.getOrDefault("X-Amz-Target")
  valid_593215 = validateParameter(valid_593215, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteConstraint"))
  if valid_593215 != nil:
    section.add "X-Amz-Target", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Signature")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Signature", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Content-Sha256", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Date")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Date", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Credential")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Credential", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Security-Token")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Security-Token", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Algorithm")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Algorithm", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-SignedHeaders", valid_593222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593224: Call_DeleteConstraint_593212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified constraint.
  ## 
  let valid = call_593224.validator(path, query, header, formData, body)
  let scheme = call_593224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593224.url(scheme.get, call_593224.host, call_593224.base,
                         call_593224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593224, url, valid)

proc call*(call_593225: Call_DeleteConstraint_593212; body: JsonNode): Recallable =
  ## deleteConstraint
  ## Deletes the specified constraint.
  ##   body: JObject (required)
  var body_593226 = newJObject()
  if body != nil:
    body_593226 = body
  result = call_593225.call(nil, nil, nil, nil, body_593226)

var deleteConstraint* = Call_DeleteConstraint_593212(name: "deleteConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint",
    validator: validate_DeleteConstraint_593213, base: "/",
    url: url_DeleteConstraint_593214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolio_593227 = ref object of OpenApiRestCall_592364
proc url_DeletePortfolio_593229(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePortfolio_593228(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593230 = header.getOrDefault("X-Amz-Target")
  valid_593230 = validateParameter(valid_593230, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolio"))
  if valid_593230 != nil:
    section.add "X-Amz-Target", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Signature")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Signature", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Content-Sha256", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Date")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Date", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Credential")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Credential", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Security-Token")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Security-Token", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Algorithm")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Algorithm", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-SignedHeaders", valid_593237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593239: Call_DeletePortfolio_593227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ## 
  let valid = call_593239.validator(path, query, header, formData, body)
  let scheme = call_593239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593239.url(scheme.get, call_593239.host, call_593239.base,
                         call_593239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593239, url, valid)

proc call*(call_593240: Call_DeletePortfolio_593227; body: JsonNode): Recallable =
  ## deletePortfolio
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ##   body: JObject (required)
  var body_593241 = newJObject()
  if body != nil:
    body_593241 = body
  result = call_593240.call(nil, nil, nil, nil, body_593241)

var deletePortfolio* = Call_DeletePortfolio_593227(name: "deletePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio",
    validator: validate_DeletePortfolio_593228, base: "/", url: url_DeletePortfolio_593229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolioShare_593242 = ref object of OpenApiRestCall_592364
proc url_DeletePortfolioShare_593244(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePortfolioShare_593243(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593245 = header.getOrDefault("X-Amz-Target")
  valid_593245 = validateParameter(valid_593245, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolioShare"))
  if valid_593245 != nil:
    section.add "X-Amz-Target", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Signature")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Signature", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Content-Sha256", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Date")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Date", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Credential")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Credential", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Security-Token")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Security-Token", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Algorithm")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Algorithm", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-SignedHeaders", valid_593252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593254: Call_DeletePortfolioShare_593242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ## 
  let valid = call_593254.validator(path, query, header, formData, body)
  let scheme = call_593254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593254.url(scheme.get, call_593254.host, call_593254.base,
                         call_593254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593254, url, valid)

proc call*(call_593255: Call_DeletePortfolioShare_593242; body: JsonNode): Recallable =
  ## deletePortfolioShare
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ##   body: JObject (required)
  var body_593256 = newJObject()
  if body != nil:
    body_593256 = body
  result = call_593255.call(nil, nil, nil, nil, body_593256)

var deletePortfolioShare* = Call_DeletePortfolioShare_593242(
    name: "deletePortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare",
    validator: validate_DeletePortfolioShare_593243, base: "/",
    url: url_DeletePortfolioShare_593244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProduct_593257 = ref object of OpenApiRestCall_592364
proc url_DeleteProduct_593259(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProduct_593258(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593260 = header.getOrDefault("X-Amz-Target")
  valid_593260 = validateParameter(valid_593260, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProduct"))
  if valid_593260 != nil:
    section.add "X-Amz-Target", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Signature")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Signature", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Content-Sha256", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Date")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Date", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Credential")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Credential", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Security-Token")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Security-Token", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-Algorithm")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Algorithm", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-SignedHeaders", valid_593267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593269: Call_DeleteProduct_593257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ## 
  let valid = call_593269.validator(path, query, header, formData, body)
  let scheme = call_593269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593269.url(scheme.get, call_593269.host, call_593269.base,
                         call_593269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593269, url, valid)

proc call*(call_593270: Call_DeleteProduct_593257; body: JsonNode): Recallable =
  ## deleteProduct
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ##   body: JObject (required)
  var body_593271 = newJObject()
  if body != nil:
    body_593271 = body
  result = call_593270.call(nil, nil, nil, nil, body_593271)

var deleteProduct* = Call_DeleteProduct_593257(name: "deleteProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct",
    validator: validate_DeleteProduct_593258, base: "/", url: url_DeleteProduct_593259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedProductPlan_593272 = ref object of OpenApiRestCall_592364
proc url_DeleteProvisionedProductPlan_593274(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProvisionedProductPlan_593273(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593275 = header.getOrDefault("X-Amz-Target")
  valid_593275 = validateParameter(valid_593275, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisionedProductPlan"))
  if valid_593275 != nil:
    section.add "X-Amz-Target", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Signature")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Signature", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Content-Sha256", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Date")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Date", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Credential")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Credential", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Security-Token")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Security-Token", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Algorithm")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Algorithm", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-SignedHeaders", valid_593282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593284: Call_DeleteProvisionedProductPlan_593272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified plan.
  ## 
  let valid = call_593284.validator(path, query, header, formData, body)
  let scheme = call_593284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593284.url(scheme.get, call_593284.host, call_593284.base,
                         call_593284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593284, url, valid)

proc call*(call_593285: Call_DeleteProvisionedProductPlan_593272; body: JsonNode): Recallable =
  ## deleteProvisionedProductPlan
  ## Deletes the specified plan.
  ##   body: JObject (required)
  var body_593286 = newJObject()
  if body != nil:
    body_593286 = body
  result = call_593285.call(nil, nil, nil, nil, body_593286)

var deleteProvisionedProductPlan* = Call_DeleteProvisionedProductPlan_593272(
    name: "deleteProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan",
    validator: validate_DeleteProvisionedProductPlan_593273, base: "/",
    url: url_DeleteProvisionedProductPlan_593274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisioningArtifact_593287 = ref object of OpenApiRestCall_592364
proc url_DeleteProvisioningArtifact_593289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProvisioningArtifact_593288(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593290 = header.getOrDefault("X-Amz-Target")
  valid_593290 = validateParameter(valid_593290, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisioningArtifact"))
  if valid_593290 != nil:
    section.add "X-Amz-Target", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Signature")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Signature", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Content-Sha256", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Date")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Date", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Credential")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Credential", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Security-Token")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Security-Token", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Algorithm")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Algorithm", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-SignedHeaders", valid_593297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593299: Call_DeleteProvisioningArtifact_593287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ## 
  let valid = call_593299.validator(path, query, header, formData, body)
  let scheme = call_593299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593299.url(scheme.get, call_593299.host, call_593299.base,
                         call_593299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593299, url, valid)

proc call*(call_593300: Call_DeleteProvisioningArtifact_593287; body: JsonNode): Recallable =
  ## deleteProvisioningArtifact
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ##   body: JObject (required)
  var body_593301 = newJObject()
  if body != nil:
    body_593301 = body
  result = call_593300.call(nil, nil, nil, nil, body_593301)

var deleteProvisioningArtifact* = Call_DeleteProvisioningArtifact_593287(
    name: "deleteProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact",
    validator: validate_DeleteProvisioningArtifact_593288, base: "/",
    url: url_DeleteProvisioningArtifact_593289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceAction_593302 = ref object of OpenApiRestCall_592364
proc url_DeleteServiceAction_593304(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteServiceAction_593303(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593305 = header.getOrDefault("X-Amz-Target")
  valid_593305 = validateParameter(valid_593305, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteServiceAction"))
  if valid_593305 != nil:
    section.add "X-Amz-Target", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Signature")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Signature", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Content-Sha256", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Date")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Date", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Credential")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Credential", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Security-Token")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Security-Token", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Algorithm")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Algorithm", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-SignedHeaders", valid_593312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593314: Call_DeleteServiceAction_593302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a self-service action.
  ## 
  let valid = call_593314.validator(path, query, header, formData, body)
  let scheme = call_593314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593314.url(scheme.get, call_593314.host, call_593314.base,
                         call_593314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593314, url, valid)

proc call*(call_593315: Call_DeleteServiceAction_593302; body: JsonNode): Recallable =
  ## deleteServiceAction
  ## Deletes a self-service action.
  ##   body: JObject (required)
  var body_593316 = newJObject()
  if body != nil:
    body_593316 = body
  result = call_593315.call(nil, nil, nil, nil, body_593316)

var deleteServiceAction* = Call_DeleteServiceAction_593302(
    name: "deleteServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction",
    validator: validate_DeleteServiceAction_593303, base: "/",
    url: url_DeleteServiceAction_593304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagOption_593317 = ref object of OpenApiRestCall_592364
proc url_DeleteTagOption_593319(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTagOption_593318(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593320 = header.getOrDefault("X-Amz-Target")
  valid_593320 = validateParameter(valid_593320, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteTagOption"))
  if valid_593320 != nil:
    section.add "X-Amz-Target", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Signature")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Signature", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Content-Sha256", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Date")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Date", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Credential")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Credential", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Security-Token")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Security-Token", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Algorithm")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Algorithm", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-SignedHeaders", valid_593327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593329: Call_DeleteTagOption_593317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ## 
  let valid = call_593329.validator(path, query, header, formData, body)
  let scheme = call_593329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593329.url(scheme.get, call_593329.host, call_593329.base,
                         call_593329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593329, url, valid)

proc call*(call_593330: Call_DeleteTagOption_593317; body: JsonNode): Recallable =
  ## deleteTagOption
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ##   body: JObject (required)
  var body_593331 = newJObject()
  if body != nil:
    body_593331 = body
  result = call_593330.call(nil, nil, nil, nil, body_593331)

var deleteTagOption* = Call_DeleteTagOption_593317(name: "deleteTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption",
    validator: validate_DeleteTagOption_593318, base: "/", url: url_DeleteTagOption_593319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConstraint_593332 = ref object of OpenApiRestCall_592364
proc url_DescribeConstraint_593334(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConstraint_593333(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593335 = header.getOrDefault("X-Amz-Target")
  valid_593335 = validateParameter(valid_593335, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeConstraint"))
  if valid_593335 != nil:
    section.add "X-Amz-Target", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Signature")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Signature", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Content-Sha256", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Date")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Date", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Credential")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Credential", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Security-Token")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Security-Token", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Algorithm")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Algorithm", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-SignedHeaders", valid_593342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593344: Call_DescribeConstraint_593332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified constraint.
  ## 
  let valid = call_593344.validator(path, query, header, formData, body)
  let scheme = call_593344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593344.url(scheme.get, call_593344.host, call_593344.base,
                         call_593344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593344, url, valid)

proc call*(call_593345: Call_DescribeConstraint_593332; body: JsonNode): Recallable =
  ## describeConstraint
  ## Gets information about the specified constraint.
  ##   body: JObject (required)
  var body_593346 = newJObject()
  if body != nil:
    body_593346 = body
  result = call_593345.call(nil, nil, nil, nil, body_593346)

var describeConstraint* = Call_DescribeConstraint_593332(
    name: "describeConstraint", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint",
    validator: validate_DescribeConstraint_593333, base: "/",
    url: url_DescribeConstraint_593334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyProductStatus_593347 = ref object of OpenApiRestCall_592364
proc url_DescribeCopyProductStatus_593349(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCopyProductStatus_593348(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593350 = header.getOrDefault("X-Amz-Target")
  valid_593350 = validateParameter(valid_593350, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeCopyProductStatus"))
  if valid_593350 != nil:
    section.add "X-Amz-Target", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Signature")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Signature", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Content-Sha256", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Date")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Date", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Credential")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Credential", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Security-Token")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Security-Token", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Algorithm")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Algorithm", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-SignedHeaders", valid_593357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593359: Call_DescribeCopyProductStatus_593347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified copy product operation.
  ## 
  let valid = call_593359.validator(path, query, header, formData, body)
  let scheme = call_593359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593359.url(scheme.get, call_593359.host, call_593359.base,
                         call_593359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593359, url, valid)

proc call*(call_593360: Call_DescribeCopyProductStatus_593347; body: JsonNode): Recallable =
  ## describeCopyProductStatus
  ## Gets the status of the specified copy product operation.
  ##   body: JObject (required)
  var body_593361 = newJObject()
  if body != nil:
    body_593361 = body
  result = call_593360.call(nil, nil, nil, nil, body_593361)

var describeCopyProductStatus* = Call_DescribeCopyProductStatus_593347(
    name: "describeCopyProductStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus",
    validator: validate_DescribeCopyProductStatus_593348, base: "/",
    url: url_DescribeCopyProductStatus_593349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolio_593362 = ref object of OpenApiRestCall_592364
proc url_DescribePortfolio_593364(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePortfolio_593363(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593365 = header.getOrDefault("X-Amz-Target")
  valid_593365 = validateParameter(valid_593365, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolio"))
  if valid_593365 != nil:
    section.add "X-Amz-Target", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Signature")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Signature", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Content-Sha256", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Date")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Date", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Credential")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Credential", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Security-Token")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Security-Token", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Algorithm")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Algorithm", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-SignedHeaders", valid_593372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593374: Call_DescribePortfolio_593362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified portfolio.
  ## 
  let valid = call_593374.validator(path, query, header, formData, body)
  let scheme = call_593374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593374.url(scheme.get, call_593374.host, call_593374.base,
                         call_593374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593374, url, valid)

proc call*(call_593375: Call_DescribePortfolio_593362; body: JsonNode): Recallable =
  ## describePortfolio
  ## Gets information about the specified portfolio.
  ##   body: JObject (required)
  var body_593376 = newJObject()
  if body != nil:
    body_593376 = body
  result = call_593375.call(nil, nil, nil, nil, body_593376)

var describePortfolio* = Call_DescribePortfolio_593362(name: "describePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio",
    validator: validate_DescribePortfolio_593363, base: "/",
    url: url_DescribePortfolio_593364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolioShareStatus_593377 = ref object of OpenApiRestCall_592364
proc url_DescribePortfolioShareStatus_593379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePortfolioShareStatus_593378(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593380 = header.getOrDefault("X-Amz-Target")
  valid_593380 = validateParameter(valid_593380, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolioShareStatus"))
  if valid_593380 != nil:
    section.add "X-Amz-Target", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Signature")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Signature", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Content-Sha256", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Date")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Date", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-Credential")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Credential", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Security-Token")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Security-Token", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Algorithm")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Algorithm", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-SignedHeaders", valid_593387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593389: Call_DescribePortfolioShareStatus_593377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ## 
  let valid = call_593389.validator(path, query, header, formData, body)
  let scheme = call_593389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593389.url(scheme.get, call_593389.host, call_593389.base,
                         call_593389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593389, url, valid)

proc call*(call_593390: Call_DescribePortfolioShareStatus_593377; body: JsonNode): Recallable =
  ## describePortfolioShareStatus
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_593391 = newJObject()
  if body != nil:
    body_593391 = body
  result = call_593390.call(nil, nil, nil, nil, body_593391)

var describePortfolioShareStatus* = Call_DescribePortfolioShareStatus_593377(
    name: "describePortfolioShareStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus",
    validator: validate_DescribePortfolioShareStatus_593378, base: "/",
    url: url_DescribePortfolioShareStatus_593379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProduct_593392 = ref object of OpenApiRestCall_592364
proc url_DescribeProduct_593394(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProduct_593393(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593395 = header.getOrDefault("X-Amz-Target")
  valid_593395 = validateParameter(valid_593395, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProduct"))
  if valid_593395 != nil:
    section.add "X-Amz-Target", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Signature")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Signature", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Content-Sha256", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Date")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Date", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-Credential")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-Credential", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Security-Token")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Security-Token", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Algorithm")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Algorithm", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-SignedHeaders", valid_593402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593404: Call_DescribeProduct_593392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_593404.validator(path, query, header, formData, body)
  let scheme = call_593404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593404.url(scheme.get, call_593404.host, call_593404.base,
                         call_593404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593404, url, valid)

proc call*(call_593405: Call_DescribeProduct_593392; body: JsonNode): Recallable =
  ## describeProduct
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_593406 = newJObject()
  if body != nil:
    body_593406 = body
  result = call_593405.call(nil, nil, nil, nil, body_593406)

var describeProduct* = Call_DescribeProduct_593392(name: "describeProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct",
    validator: validate_DescribeProduct_593393, base: "/", url: url_DescribeProduct_593394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductAsAdmin_593407 = ref object of OpenApiRestCall_592364
proc url_DescribeProductAsAdmin_593409(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProductAsAdmin_593408(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593410 = header.getOrDefault("X-Amz-Target")
  valid_593410 = validateParameter(valid_593410, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductAsAdmin"))
  if valid_593410 != nil:
    section.add "X-Amz-Target", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Signature")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Signature", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Content-Sha256", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Date")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Date", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Credential")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Credential", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Security-Token")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Security-Token", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Algorithm")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Algorithm", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-SignedHeaders", valid_593417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593419: Call_DescribeProductAsAdmin_593407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product. This operation is run with administrator access.
  ## 
  let valid = call_593419.validator(path, query, header, formData, body)
  let scheme = call_593419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593419.url(scheme.get, call_593419.host, call_593419.base,
                         call_593419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593419, url, valid)

proc call*(call_593420: Call_DescribeProductAsAdmin_593407; body: JsonNode): Recallable =
  ## describeProductAsAdmin
  ## Gets information about the specified product. This operation is run with administrator access.
  ##   body: JObject (required)
  var body_593421 = newJObject()
  if body != nil:
    body_593421 = body
  result = call_593420.call(nil, nil, nil, nil, body_593421)

var describeProductAsAdmin* = Call_DescribeProductAsAdmin_593407(
    name: "describeProductAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin",
    validator: validate_DescribeProductAsAdmin_593408, base: "/",
    url: url_DescribeProductAsAdmin_593409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductView_593422 = ref object of OpenApiRestCall_592364
proc url_DescribeProductView_593424(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProductView_593423(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593425 = header.getOrDefault("X-Amz-Target")
  valid_593425 = validateParameter(valid_593425, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductView"))
  if valid_593425 != nil:
    section.add "X-Amz-Target", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Signature")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Signature", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Content-Sha256", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Date")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Date", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Credential")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Credential", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Security-Token")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Security-Token", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Algorithm")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Algorithm", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-SignedHeaders", valid_593432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593434: Call_DescribeProductView_593422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_593434.validator(path, query, header, formData, body)
  let scheme = call_593434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593434.url(scheme.get, call_593434.host, call_593434.base,
                         call_593434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593434, url, valid)

proc call*(call_593435: Call_DescribeProductView_593422; body: JsonNode): Recallable =
  ## describeProductView
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_593436 = newJObject()
  if body != nil:
    body_593436 = body
  result = call_593435.call(nil, nil, nil, nil, body_593436)

var describeProductView* = Call_DescribeProductView_593422(
    name: "describeProductView", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView",
    validator: validate_DescribeProductView_593423, base: "/",
    url: url_DescribeProductView_593424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProduct_593437 = ref object of OpenApiRestCall_592364
proc url_DescribeProvisionedProduct_593439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProvisionedProduct_593438(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593440 = header.getOrDefault("X-Amz-Target")
  valid_593440 = validateParameter(valid_593440, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProduct"))
  if valid_593440 != nil:
    section.add "X-Amz-Target", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Signature")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Signature", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Content-Sha256", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Date")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Date", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-Credential")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Credential", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-Security-Token")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-Security-Token", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Algorithm")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Algorithm", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-SignedHeaders", valid_593447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593449: Call_DescribeProvisionedProduct_593437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioned product.
  ## 
  let valid = call_593449.validator(path, query, header, formData, body)
  let scheme = call_593449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593449.url(scheme.get, call_593449.host, call_593449.base,
                         call_593449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593449, url, valid)

proc call*(call_593450: Call_DescribeProvisionedProduct_593437; body: JsonNode): Recallable =
  ## describeProvisionedProduct
  ## Gets information about the specified provisioned product.
  ##   body: JObject (required)
  var body_593451 = newJObject()
  if body != nil:
    body_593451 = body
  result = call_593450.call(nil, nil, nil, nil, body_593451)

var describeProvisionedProduct* = Call_DescribeProvisionedProduct_593437(
    name: "describeProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct",
    validator: validate_DescribeProvisionedProduct_593438, base: "/",
    url: url_DescribeProvisionedProduct_593439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProductPlan_593452 = ref object of OpenApiRestCall_592364
proc url_DescribeProvisionedProductPlan_593454(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProvisionedProductPlan_593453(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593455 = header.getOrDefault("X-Amz-Target")
  valid_593455 = validateParameter(valid_593455, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProductPlan"))
  if valid_593455 != nil:
    section.add "X-Amz-Target", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-Signature")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-Signature", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Content-Sha256", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Date")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Date", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-Credential")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Credential", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Security-Token")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Security-Token", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Algorithm")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Algorithm", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-SignedHeaders", valid_593462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593464: Call_DescribeProvisionedProductPlan_593452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the resource changes for the specified plan.
  ## 
  let valid = call_593464.validator(path, query, header, formData, body)
  let scheme = call_593464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593464.url(scheme.get, call_593464.host, call_593464.base,
                         call_593464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593464, url, valid)

proc call*(call_593465: Call_DescribeProvisionedProductPlan_593452; body: JsonNode): Recallable =
  ## describeProvisionedProductPlan
  ## Gets information about the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_593466 = newJObject()
  if body != nil:
    body_593466 = body
  result = call_593465.call(nil, nil, nil, nil, body_593466)

var describeProvisionedProductPlan* = Call_DescribeProvisionedProductPlan_593452(
    name: "describeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan",
    validator: validate_DescribeProvisionedProductPlan_593453, base: "/",
    url: url_DescribeProvisionedProductPlan_593454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningArtifact_593467 = ref object of OpenApiRestCall_592364
proc url_DescribeProvisioningArtifact_593469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProvisioningArtifact_593468(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593470 = header.getOrDefault("X-Amz-Target")
  valid_593470 = validateParameter(valid_593470, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningArtifact"))
  if valid_593470 != nil:
    section.add "X-Amz-Target", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Signature")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Signature", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Content-Sha256", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Date")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Date", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Credential")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Credential", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Security-Token")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Security-Token", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Algorithm")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Algorithm", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-SignedHeaders", valid_593477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593479: Call_DescribeProvisioningArtifact_593467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ## 
  let valid = call_593479.validator(path, query, header, formData, body)
  let scheme = call_593479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593479.url(scheme.get, call_593479.host, call_593479.base,
                         call_593479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593479, url, valid)

proc call*(call_593480: Call_DescribeProvisioningArtifact_593467; body: JsonNode): Recallable =
  ## describeProvisioningArtifact
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ##   body: JObject (required)
  var body_593481 = newJObject()
  if body != nil:
    body_593481 = body
  result = call_593480.call(nil, nil, nil, nil, body_593481)

var describeProvisioningArtifact* = Call_DescribeProvisioningArtifact_593467(
    name: "describeProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact",
    validator: validate_DescribeProvisioningArtifact_593468, base: "/",
    url: url_DescribeProvisioningArtifact_593469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningParameters_593482 = ref object of OpenApiRestCall_592364
proc url_DescribeProvisioningParameters_593484(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProvisioningParameters_593483(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593485 = header.getOrDefault("X-Amz-Target")
  valid_593485 = validateParameter(valid_593485, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningParameters"))
  if valid_593485 != nil:
    section.add "X-Amz-Target", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Signature")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Signature", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Content-Sha256", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Date")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Date", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Credential")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Credential", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-Security-Token")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Security-Token", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-Algorithm")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-Algorithm", valid_593491
  var valid_593492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "X-Amz-SignedHeaders", valid_593492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593494: Call_DescribeProvisioningParameters_593482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ## 
  let valid = call_593494.validator(path, query, header, formData, body)
  let scheme = call_593494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593494.url(scheme.get, call_593494.host, call_593494.base,
                         call_593494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593494, url, valid)

proc call*(call_593495: Call_DescribeProvisioningParameters_593482; body: JsonNode): Recallable =
  ## describeProvisioningParameters
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ##   body: JObject (required)
  var body_593496 = newJObject()
  if body != nil:
    body_593496 = body
  result = call_593495.call(nil, nil, nil, nil, body_593496)

var describeProvisioningParameters* = Call_DescribeProvisioningParameters_593482(
    name: "describeProvisioningParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters",
    validator: validate_DescribeProvisioningParameters_593483, base: "/",
    url: url_DescribeProvisioningParameters_593484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecord_593497 = ref object of OpenApiRestCall_592364
proc url_DescribeRecord_593499(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRecord_593498(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593500 = header.getOrDefault("X-Amz-Target")
  valid_593500 = validateParameter(valid_593500, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeRecord"))
  if valid_593500 != nil:
    section.add "X-Amz-Target", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Signature")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Signature", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Content-Sha256", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Date")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Date", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Credential")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Credential", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-Security-Token")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Security-Token", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-Algorithm")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Algorithm", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-SignedHeaders", valid_593507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593509: Call_DescribeRecord_593497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ## 
  let valid = call_593509.validator(path, query, header, formData, body)
  let scheme = call_593509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593509.url(scheme.get, call_593509.host, call_593509.base,
                         call_593509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593509, url, valid)

proc call*(call_593510: Call_DescribeRecord_593497; body: JsonNode): Recallable =
  ## describeRecord
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ##   body: JObject (required)
  var body_593511 = newJObject()
  if body != nil:
    body_593511 = body
  result = call_593510.call(nil, nil, nil, nil, body_593511)

var describeRecord* = Call_DescribeRecord_593497(name: "describeRecord",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord",
    validator: validate_DescribeRecord_593498, base: "/", url: url_DescribeRecord_593499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceAction_593512 = ref object of OpenApiRestCall_592364
proc url_DescribeServiceAction_593514(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeServiceAction_593513(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593515 = header.getOrDefault("X-Amz-Target")
  valid_593515 = validateParameter(valid_593515, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceAction"))
  if valid_593515 != nil:
    section.add "X-Amz-Target", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Signature")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Signature", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Content-Sha256", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Date")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Date", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Credential")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Credential", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Security-Token")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Security-Token", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Algorithm")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Algorithm", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-SignedHeaders", valid_593522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593524: Call_DescribeServiceAction_593512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a self-service action.
  ## 
  let valid = call_593524.validator(path, query, header, formData, body)
  let scheme = call_593524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593524.url(scheme.get, call_593524.host, call_593524.base,
                         call_593524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593524, url, valid)

proc call*(call_593525: Call_DescribeServiceAction_593512; body: JsonNode): Recallable =
  ## describeServiceAction
  ## Describes a self-service action.
  ##   body: JObject (required)
  var body_593526 = newJObject()
  if body != nil:
    body_593526 = body
  result = call_593525.call(nil, nil, nil, nil, body_593526)

var describeServiceAction* = Call_DescribeServiceAction_593512(
    name: "describeServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction",
    validator: validate_DescribeServiceAction_593513, base: "/",
    url: url_DescribeServiceAction_593514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceActionExecutionParameters_593527 = ref object of OpenApiRestCall_592364
proc url_DescribeServiceActionExecutionParameters_593529(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeServiceActionExecutionParameters_593528(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593530 = header.getOrDefault("X-Amz-Target")
  valid_593530 = validateParameter(valid_593530, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"))
  if valid_593530 != nil:
    section.add "X-Amz-Target", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-Signature")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-Signature", valid_593531
  var valid_593532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Content-Sha256", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Date")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Date", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Credential")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Credential", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Security-Token")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Security-Token", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-Algorithm")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Algorithm", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-SignedHeaders", valid_593537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593539: Call_DescribeServiceActionExecutionParameters_593527;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593539.validator(path, query, header, formData, body)
  let scheme = call_593539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593539.url(scheme.get, call_593539.host, call_593539.base,
                         call_593539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593539, url, valid)

proc call*(call_593540: Call_DescribeServiceActionExecutionParameters_593527;
          body: JsonNode): Recallable =
  ## describeServiceActionExecutionParameters
  ##   body: JObject (required)
  var body_593541 = newJObject()
  if body != nil:
    body_593541 = body
  result = call_593540.call(nil, nil, nil, nil, body_593541)

var describeServiceActionExecutionParameters* = Call_DescribeServiceActionExecutionParameters_593527(
    name: "describeServiceActionExecutionParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters",
    validator: validate_DescribeServiceActionExecutionParameters_593528,
    base: "/", url: url_DescribeServiceActionExecutionParameters_593529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTagOption_593542 = ref object of OpenApiRestCall_592364
proc url_DescribeTagOption_593544(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTagOption_593543(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593545 = header.getOrDefault("X-Amz-Target")
  valid_593545 = validateParameter(valid_593545, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeTagOption"))
  if valid_593545 != nil:
    section.add "X-Amz-Target", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-Signature")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-Signature", valid_593546
  var valid_593547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Content-Sha256", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Date")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Date", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Credential")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Credential", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-Security-Token")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-Security-Token", valid_593550
  var valid_593551 = header.getOrDefault("X-Amz-Algorithm")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Algorithm", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-SignedHeaders", valid_593552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593554: Call_DescribeTagOption_593542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified TagOption.
  ## 
  let valid = call_593554.validator(path, query, header, formData, body)
  let scheme = call_593554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593554.url(scheme.get, call_593554.host, call_593554.base,
                         call_593554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593554, url, valid)

proc call*(call_593555: Call_DescribeTagOption_593542; body: JsonNode): Recallable =
  ## describeTagOption
  ## Gets information about the specified TagOption.
  ##   body: JObject (required)
  var body_593556 = newJObject()
  if body != nil:
    body_593556 = body
  result = call_593555.call(nil, nil, nil, nil, body_593556)

var describeTagOption* = Call_DescribeTagOption_593542(name: "describeTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption",
    validator: validate_DescribeTagOption_593543, base: "/",
    url: url_DescribeTagOption_593544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSOrganizationsAccess_593557 = ref object of OpenApiRestCall_592364
proc url_DisableAWSOrganizationsAccess_593559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableAWSOrganizationsAccess_593558(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593560 = header.getOrDefault("X-Amz-Target")
  valid_593560 = validateParameter(valid_593560, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"))
  if valid_593560 != nil:
    section.add "X-Amz-Target", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Signature")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Signature", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Content-Sha256", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-Date")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Date", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-Credential")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-Credential", valid_593564
  var valid_593565 = header.getOrDefault("X-Amz-Security-Token")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-Security-Token", valid_593565
  var valid_593566 = header.getOrDefault("X-Amz-Algorithm")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Algorithm", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-SignedHeaders", valid_593567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593569: Call_DisableAWSOrganizationsAccess_593557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ## 
  let valid = call_593569.validator(path, query, header, formData, body)
  let scheme = call_593569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593569.url(scheme.get, call_593569.host, call_593569.base,
                         call_593569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593569, url, valid)

proc call*(call_593570: Call_DisableAWSOrganizationsAccess_593557; body: JsonNode): Recallable =
  ## disableAWSOrganizationsAccess
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_593571 = newJObject()
  if body != nil:
    body_593571 = body
  result = call_593570.call(nil, nil, nil, nil, body_593571)

var disableAWSOrganizationsAccess* = Call_DisableAWSOrganizationsAccess_593557(
    name: "disableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess",
    validator: validate_DisableAWSOrganizationsAccess_593558, base: "/",
    url: url_DisableAWSOrganizationsAccess_593559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateBudgetFromResource_593572 = ref object of OpenApiRestCall_592364
proc url_DisassociateBudgetFromResource_593574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateBudgetFromResource_593573(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593575 = header.getOrDefault("X-Amz-Target")
  valid_593575 = validateParameter(valid_593575, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateBudgetFromResource"))
  if valid_593575 != nil:
    section.add "X-Amz-Target", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-Signature")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Signature", valid_593576
  var valid_593577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "X-Amz-Content-Sha256", valid_593577
  var valid_593578 = header.getOrDefault("X-Amz-Date")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "X-Amz-Date", valid_593578
  var valid_593579 = header.getOrDefault("X-Amz-Credential")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Credential", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-Security-Token")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-Security-Token", valid_593580
  var valid_593581 = header.getOrDefault("X-Amz-Algorithm")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Algorithm", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-SignedHeaders", valid_593582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593584: Call_DisassociateBudgetFromResource_593572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified budget from the specified resource.
  ## 
  let valid = call_593584.validator(path, query, header, formData, body)
  let scheme = call_593584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593584.url(scheme.get, call_593584.host, call_593584.base,
                         call_593584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593584, url, valid)

proc call*(call_593585: Call_DisassociateBudgetFromResource_593572; body: JsonNode): Recallable =
  ## disassociateBudgetFromResource
  ## Disassociates the specified budget from the specified resource.
  ##   body: JObject (required)
  var body_593586 = newJObject()
  if body != nil:
    body_593586 = body
  result = call_593585.call(nil, nil, nil, nil, body_593586)

var disassociateBudgetFromResource* = Call_DisassociateBudgetFromResource_593572(
    name: "disassociateBudgetFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource",
    validator: validate_DisassociateBudgetFromResource_593573, base: "/",
    url: url_DisassociateBudgetFromResource_593574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePrincipalFromPortfolio_593587 = ref object of OpenApiRestCall_592364
proc url_DisassociatePrincipalFromPortfolio_593589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociatePrincipalFromPortfolio_593588(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593590 = header.getOrDefault("X-Amz-Target")
  valid_593590 = validateParameter(valid_593590, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"))
  if valid_593590 != nil:
    section.add "X-Amz-Target", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Signature")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Signature", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Content-Sha256", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-Date")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-Date", valid_593593
  var valid_593594 = header.getOrDefault("X-Amz-Credential")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Credential", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-Security-Token")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-Security-Token", valid_593595
  var valid_593596 = header.getOrDefault("X-Amz-Algorithm")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Algorithm", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-SignedHeaders", valid_593597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593599: Call_DisassociatePrincipalFromPortfolio_593587;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ## 
  let valid = call_593599.validator(path, query, header, formData, body)
  let scheme = call_593599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593599.url(scheme.get, call_593599.host, call_593599.base,
                         call_593599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593599, url, valid)

proc call*(call_593600: Call_DisassociatePrincipalFromPortfolio_593587;
          body: JsonNode): Recallable =
  ## disassociatePrincipalFromPortfolio
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ##   body: JObject (required)
  var body_593601 = newJObject()
  if body != nil:
    body_593601 = body
  result = call_593600.call(nil, nil, nil, nil, body_593601)

var disassociatePrincipalFromPortfolio* = Call_DisassociatePrincipalFromPortfolio_593587(
    name: "disassociatePrincipalFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio",
    validator: validate_DisassociatePrincipalFromPortfolio_593588, base: "/",
    url: url_DisassociatePrincipalFromPortfolio_593589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateProductFromPortfolio_593602 = ref object of OpenApiRestCall_592364
proc url_DisassociateProductFromPortfolio_593604(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateProductFromPortfolio_593603(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593605 = header.getOrDefault("X-Amz-Target")
  valid_593605 = validateParameter(valid_593605, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateProductFromPortfolio"))
  if valid_593605 != nil:
    section.add "X-Amz-Target", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-Signature")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Signature", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Content-Sha256", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Date")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Date", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-Credential")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-Credential", valid_593609
  var valid_593610 = header.getOrDefault("X-Amz-Security-Token")
  valid_593610 = validateParameter(valid_593610, JString, required = false,
                                 default = nil)
  if valid_593610 != nil:
    section.add "X-Amz-Security-Token", valid_593610
  var valid_593611 = header.getOrDefault("X-Amz-Algorithm")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "X-Amz-Algorithm", valid_593611
  var valid_593612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593612 = validateParameter(valid_593612, JString, required = false,
                                 default = nil)
  if valid_593612 != nil:
    section.add "X-Amz-SignedHeaders", valid_593612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593614: Call_DisassociateProductFromPortfolio_593602;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified product from the specified portfolio. 
  ## 
  let valid = call_593614.validator(path, query, header, formData, body)
  let scheme = call_593614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593614.url(scheme.get, call_593614.host, call_593614.base,
                         call_593614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593614, url, valid)

proc call*(call_593615: Call_DisassociateProductFromPortfolio_593602;
          body: JsonNode): Recallable =
  ## disassociateProductFromPortfolio
  ## Disassociates the specified product from the specified portfolio. 
  ##   body: JObject (required)
  var body_593616 = newJObject()
  if body != nil:
    body_593616 = body
  result = call_593615.call(nil, nil, nil, nil, body_593616)

var disassociateProductFromPortfolio* = Call_DisassociateProductFromPortfolio_593602(
    name: "disassociateProductFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio",
    validator: validate_DisassociateProductFromPortfolio_593603, base: "/",
    url: url_DisassociateProductFromPortfolio_593604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceActionFromProvisioningArtifact_593617 = ref object of OpenApiRestCall_592364
proc url_DisassociateServiceActionFromProvisioningArtifact_593619(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateServiceActionFromProvisioningArtifact_593618(
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593620 = header.getOrDefault("X-Amz-Target")
  valid_593620 = validateParameter(valid_593620, JString, required = true, default = newJString("AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"))
  if valid_593620 != nil:
    section.add "X-Amz-Target", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Signature")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Signature", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Content-Sha256", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Date")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Date", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Credential")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Credential", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Security-Token")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Security-Token", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Algorithm")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Algorithm", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-SignedHeaders", valid_593627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593629: Call_DisassociateServiceActionFromProvisioningArtifact_593617;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ## 
  let valid = call_593629.validator(path, query, header, formData, body)
  let scheme = call_593629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593629.url(scheme.get, call_593629.host, call_593629.base,
                         call_593629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593629, url, valid)

proc call*(call_593630: Call_DisassociateServiceActionFromProvisioningArtifact_593617;
          body: JsonNode): Recallable =
  ## disassociateServiceActionFromProvisioningArtifact
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_593631 = newJObject()
  if body != nil:
    body_593631 = body
  result = call_593630.call(nil, nil, nil, nil, body_593631)

var disassociateServiceActionFromProvisioningArtifact* = Call_DisassociateServiceActionFromProvisioningArtifact_593617(
    name: "disassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact",
    validator: validate_DisassociateServiceActionFromProvisioningArtifact_593618,
    base: "/", url: url_DisassociateServiceActionFromProvisioningArtifact_593619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTagOptionFromResource_593632 = ref object of OpenApiRestCall_592364
proc url_DisassociateTagOptionFromResource_593634(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateTagOptionFromResource_593633(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593635 = header.getOrDefault("X-Amz-Target")
  valid_593635 = validateParameter(valid_593635, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateTagOptionFromResource"))
  if valid_593635 != nil:
    section.add "X-Amz-Target", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-Signature")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Signature", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Content-Sha256", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-Date")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-Date", valid_593638
  var valid_593639 = header.getOrDefault("X-Amz-Credential")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Credential", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Security-Token")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Security-Token", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Algorithm")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Algorithm", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-SignedHeaders", valid_593642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593644: Call_DisassociateTagOptionFromResource_593632;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified TagOption from the specified resource.
  ## 
  let valid = call_593644.validator(path, query, header, formData, body)
  let scheme = call_593644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593644.url(scheme.get, call_593644.host, call_593644.base,
                         call_593644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593644, url, valid)

proc call*(call_593645: Call_DisassociateTagOptionFromResource_593632;
          body: JsonNode): Recallable =
  ## disassociateTagOptionFromResource
  ## Disassociates the specified TagOption from the specified resource.
  ##   body: JObject (required)
  var body_593646 = newJObject()
  if body != nil:
    body_593646 = body
  result = call_593645.call(nil, nil, nil, nil, body_593646)

var disassociateTagOptionFromResource* = Call_DisassociateTagOptionFromResource_593632(
    name: "disassociateTagOptionFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource",
    validator: validate_DisassociateTagOptionFromResource_593633, base: "/",
    url: url_DisassociateTagOptionFromResource_593634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSOrganizationsAccess_593647 = ref object of OpenApiRestCall_592364
proc url_EnableAWSOrganizationsAccess_593649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableAWSOrganizationsAccess_593648(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593650 = header.getOrDefault("X-Amz-Target")
  valid_593650 = validateParameter(valid_593650, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"))
  if valid_593650 != nil:
    section.add "X-Amz-Target", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Signature")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Signature", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Content-Sha256", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Date")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Date", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Credential")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Credential", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-Security-Token")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-Security-Token", valid_593655
  var valid_593656 = header.getOrDefault("X-Amz-Algorithm")
  valid_593656 = validateParameter(valid_593656, JString, required = false,
                                 default = nil)
  if valid_593656 != nil:
    section.add "X-Amz-Algorithm", valid_593656
  var valid_593657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-SignedHeaders", valid_593657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593659: Call_EnableAWSOrganizationsAccess_593647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ## 
  let valid = call_593659.validator(path, query, header, formData, body)
  let scheme = call_593659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593659.url(scheme.get, call_593659.host, call_593659.base,
                         call_593659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593659, url, valid)

proc call*(call_593660: Call_EnableAWSOrganizationsAccess_593647; body: JsonNode): Recallable =
  ## enableAWSOrganizationsAccess
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ##   body: JObject (required)
  var body_593661 = newJObject()
  if body != nil:
    body_593661 = body
  result = call_593660.call(nil, nil, nil, nil, body_593661)

var enableAWSOrganizationsAccess* = Call_EnableAWSOrganizationsAccess_593647(
    name: "enableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess",
    validator: validate_EnableAWSOrganizationsAccess_593648, base: "/",
    url: url_EnableAWSOrganizationsAccess_593649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductPlan_593662 = ref object of OpenApiRestCall_592364
proc url_ExecuteProvisionedProductPlan_593664(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExecuteProvisionedProductPlan_593663(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593665 = header.getOrDefault("X-Amz-Target")
  valid_593665 = validateParameter(valid_593665, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"))
  if valid_593665 != nil:
    section.add "X-Amz-Target", valid_593665
  var valid_593666 = header.getOrDefault("X-Amz-Signature")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Signature", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-Content-Sha256", valid_593667
  var valid_593668 = header.getOrDefault("X-Amz-Date")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Date", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-Credential")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-Credential", valid_593669
  var valid_593670 = header.getOrDefault("X-Amz-Security-Token")
  valid_593670 = validateParameter(valid_593670, JString, required = false,
                                 default = nil)
  if valid_593670 != nil:
    section.add "X-Amz-Security-Token", valid_593670
  var valid_593671 = header.getOrDefault("X-Amz-Algorithm")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "X-Amz-Algorithm", valid_593671
  var valid_593672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "X-Amz-SignedHeaders", valid_593672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593674: Call_ExecuteProvisionedProductPlan_593662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ## 
  let valid = call_593674.validator(path, query, header, formData, body)
  let scheme = call_593674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593674.url(scheme.get, call_593674.host, call_593674.base,
                         call_593674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593674, url, valid)

proc call*(call_593675: Call_ExecuteProvisionedProductPlan_593662; body: JsonNode): Recallable =
  ## executeProvisionedProductPlan
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_593676 = newJObject()
  if body != nil:
    body_593676 = body
  result = call_593675.call(nil, nil, nil, nil, body_593676)

var executeProvisionedProductPlan* = Call_ExecuteProvisionedProductPlan_593662(
    name: "executeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan",
    validator: validate_ExecuteProvisionedProductPlan_593663, base: "/",
    url: url_ExecuteProvisionedProductPlan_593664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductServiceAction_593677 = ref object of OpenApiRestCall_592364
proc url_ExecuteProvisionedProductServiceAction_593679(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExecuteProvisionedProductServiceAction_593678(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593680 = header.getOrDefault("X-Amz-Target")
  valid_593680 = validateParameter(valid_593680, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"))
  if valid_593680 != nil:
    section.add "X-Amz-Target", valid_593680
  var valid_593681 = header.getOrDefault("X-Amz-Signature")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "X-Amz-Signature", valid_593681
  var valid_593682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "X-Amz-Content-Sha256", valid_593682
  var valid_593683 = header.getOrDefault("X-Amz-Date")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "X-Amz-Date", valid_593683
  var valid_593684 = header.getOrDefault("X-Amz-Credential")
  valid_593684 = validateParameter(valid_593684, JString, required = false,
                                 default = nil)
  if valid_593684 != nil:
    section.add "X-Amz-Credential", valid_593684
  var valid_593685 = header.getOrDefault("X-Amz-Security-Token")
  valid_593685 = validateParameter(valid_593685, JString, required = false,
                                 default = nil)
  if valid_593685 != nil:
    section.add "X-Amz-Security-Token", valid_593685
  var valid_593686 = header.getOrDefault("X-Amz-Algorithm")
  valid_593686 = validateParameter(valid_593686, JString, required = false,
                                 default = nil)
  if valid_593686 != nil:
    section.add "X-Amz-Algorithm", valid_593686
  var valid_593687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593687 = validateParameter(valid_593687, JString, required = false,
                                 default = nil)
  if valid_593687 != nil:
    section.add "X-Amz-SignedHeaders", valid_593687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593689: Call_ExecuteProvisionedProductServiceAction_593677;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Executes a self-service action against a provisioned product.
  ## 
  let valid = call_593689.validator(path, query, header, formData, body)
  let scheme = call_593689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593689.url(scheme.get, call_593689.host, call_593689.base,
                         call_593689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593689, url, valid)

proc call*(call_593690: Call_ExecuteProvisionedProductServiceAction_593677;
          body: JsonNode): Recallable =
  ## executeProvisionedProductServiceAction
  ## Executes a self-service action against a provisioned product.
  ##   body: JObject (required)
  var body_593691 = newJObject()
  if body != nil:
    body_593691 = body
  result = call_593690.call(nil, nil, nil, nil, body_593691)

var executeProvisionedProductServiceAction* = Call_ExecuteProvisionedProductServiceAction_593677(
    name: "executeProvisionedProductServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction",
    validator: validate_ExecuteProvisionedProductServiceAction_593678, base: "/",
    url: url_ExecuteProvisionedProductServiceAction_593679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSOrganizationsAccessStatus_593692 = ref object of OpenApiRestCall_592364
proc url_GetAWSOrganizationsAccessStatus_593694(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAWSOrganizationsAccessStatus_593693(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593695 = header.getOrDefault("X-Amz-Target")
  valid_593695 = validateParameter(valid_593695, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"))
  if valid_593695 != nil:
    section.add "X-Amz-Target", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-Signature")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-Signature", valid_593696
  var valid_593697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Content-Sha256", valid_593697
  var valid_593698 = header.getOrDefault("X-Amz-Date")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "X-Amz-Date", valid_593698
  var valid_593699 = header.getOrDefault("X-Amz-Credential")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "X-Amz-Credential", valid_593699
  var valid_593700 = header.getOrDefault("X-Amz-Security-Token")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "X-Amz-Security-Token", valid_593700
  var valid_593701 = header.getOrDefault("X-Amz-Algorithm")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "X-Amz-Algorithm", valid_593701
  var valid_593702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "X-Amz-SignedHeaders", valid_593702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593704: Call_GetAWSOrganizationsAccessStatus_593692;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ## 
  let valid = call_593704.validator(path, query, header, formData, body)
  let scheme = call_593704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593704.url(scheme.get, call_593704.host, call_593704.base,
                         call_593704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593704, url, valid)

proc call*(call_593705: Call_GetAWSOrganizationsAccessStatus_593692; body: JsonNode): Recallable =
  ## getAWSOrganizationsAccessStatus
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_593706 = newJObject()
  if body != nil:
    body_593706 = body
  result = call_593705.call(nil, nil, nil, nil, body_593706)

var getAWSOrganizationsAccessStatus* = Call_GetAWSOrganizationsAccessStatus_593692(
    name: "getAWSOrganizationsAccessStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus",
    validator: validate_GetAWSOrganizationsAccessStatus_593693, base: "/",
    url: url_GetAWSOrganizationsAccessStatus_593694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAcceptedPortfolioShares_593707 = ref object of OpenApiRestCall_592364
proc url_ListAcceptedPortfolioShares_593709(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAcceptedPortfolioShares_593708(path: JsonNode; query: JsonNode;
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
  var valid_593710 = query.getOrDefault("PageToken")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "PageToken", valid_593710
  var valid_593711 = query.getOrDefault("PageSize")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "PageSize", valid_593711
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593712 = header.getOrDefault("X-Amz-Target")
  valid_593712 = validateParameter(valid_593712, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListAcceptedPortfolioShares"))
  if valid_593712 != nil:
    section.add "X-Amz-Target", valid_593712
  var valid_593713 = header.getOrDefault("X-Amz-Signature")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "X-Amz-Signature", valid_593713
  var valid_593714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593714 = validateParameter(valid_593714, JString, required = false,
                                 default = nil)
  if valid_593714 != nil:
    section.add "X-Amz-Content-Sha256", valid_593714
  var valid_593715 = header.getOrDefault("X-Amz-Date")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "X-Amz-Date", valid_593715
  var valid_593716 = header.getOrDefault("X-Amz-Credential")
  valid_593716 = validateParameter(valid_593716, JString, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "X-Amz-Credential", valid_593716
  var valid_593717 = header.getOrDefault("X-Amz-Security-Token")
  valid_593717 = validateParameter(valid_593717, JString, required = false,
                                 default = nil)
  if valid_593717 != nil:
    section.add "X-Amz-Security-Token", valid_593717
  var valid_593718 = header.getOrDefault("X-Amz-Algorithm")
  valid_593718 = validateParameter(valid_593718, JString, required = false,
                                 default = nil)
  if valid_593718 != nil:
    section.add "X-Amz-Algorithm", valid_593718
  var valid_593719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593719 = validateParameter(valid_593719, JString, required = false,
                                 default = nil)
  if valid_593719 != nil:
    section.add "X-Amz-SignedHeaders", valid_593719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593721: Call_ListAcceptedPortfolioShares_593707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  let valid = call_593721.validator(path, query, header, formData, body)
  let scheme = call_593721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593721.url(scheme.get, call_593721.host, call_593721.base,
                         call_593721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593721, url, valid)

proc call*(call_593722: Call_ListAcceptedPortfolioShares_593707; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listAcceptedPortfolioShares
  ## Lists all portfolios for which sharing was accepted by this account.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593723 = newJObject()
  var body_593724 = newJObject()
  add(query_593723, "PageToken", newJString(PageToken))
  add(query_593723, "PageSize", newJString(PageSize))
  if body != nil:
    body_593724 = body
  result = call_593722.call(nil, query_593723, nil, nil, body_593724)

var listAcceptedPortfolioShares* = Call_ListAcceptedPortfolioShares_593707(
    name: "listAcceptedPortfolioShares", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares",
    validator: validate_ListAcceptedPortfolioShares_593708, base: "/",
    url: url_ListAcceptedPortfolioShares_593709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBudgetsForResource_593726 = ref object of OpenApiRestCall_592364
proc url_ListBudgetsForResource_593728(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBudgetsForResource_593727(path: JsonNode; query: JsonNode;
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
  var valid_593729 = query.getOrDefault("PageToken")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "PageToken", valid_593729
  var valid_593730 = query.getOrDefault("PageSize")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "PageSize", valid_593730
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593731 = header.getOrDefault("X-Amz-Target")
  valid_593731 = validateParameter(valid_593731, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListBudgetsForResource"))
  if valid_593731 != nil:
    section.add "X-Amz-Target", valid_593731
  var valid_593732 = header.getOrDefault("X-Amz-Signature")
  valid_593732 = validateParameter(valid_593732, JString, required = false,
                                 default = nil)
  if valid_593732 != nil:
    section.add "X-Amz-Signature", valid_593732
  var valid_593733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593733 = validateParameter(valid_593733, JString, required = false,
                                 default = nil)
  if valid_593733 != nil:
    section.add "X-Amz-Content-Sha256", valid_593733
  var valid_593734 = header.getOrDefault("X-Amz-Date")
  valid_593734 = validateParameter(valid_593734, JString, required = false,
                                 default = nil)
  if valid_593734 != nil:
    section.add "X-Amz-Date", valid_593734
  var valid_593735 = header.getOrDefault("X-Amz-Credential")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "X-Amz-Credential", valid_593735
  var valid_593736 = header.getOrDefault("X-Amz-Security-Token")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "X-Amz-Security-Token", valid_593736
  var valid_593737 = header.getOrDefault("X-Amz-Algorithm")
  valid_593737 = validateParameter(valid_593737, JString, required = false,
                                 default = nil)
  if valid_593737 != nil:
    section.add "X-Amz-Algorithm", valid_593737
  var valid_593738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593738 = validateParameter(valid_593738, JString, required = false,
                                 default = nil)
  if valid_593738 != nil:
    section.add "X-Amz-SignedHeaders", valid_593738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593740: Call_ListBudgetsForResource_593726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the budgets associated to the specified resource.
  ## 
  let valid = call_593740.validator(path, query, header, formData, body)
  let scheme = call_593740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593740.url(scheme.get, call_593740.host, call_593740.base,
                         call_593740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593740, url, valid)

proc call*(call_593741: Call_ListBudgetsForResource_593726; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listBudgetsForResource
  ## Lists all the budgets associated to the specified resource.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593742 = newJObject()
  var body_593743 = newJObject()
  add(query_593742, "PageToken", newJString(PageToken))
  add(query_593742, "PageSize", newJString(PageSize))
  if body != nil:
    body_593743 = body
  result = call_593741.call(nil, query_593742, nil, nil, body_593743)

var listBudgetsForResource* = Call_ListBudgetsForResource_593726(
    name: "listBudgetsForResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource",
    validator: validate_ListBudgetsForResource_593727, base: "/",
    url: url_ListBudgetsForResource_593728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConstraintsForPortfolio_593744 = ref object of OpenApiRestCall_592364
proc url_ListConstraintsForPortfolio_593746(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConstraintsForPortfolio_593745(path: JsonNode; query: JsonNode;
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
  var valid_593747 = query.getOrDefault("PageToken")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "PageToken", valid_593747
  var valid_593748 = query.getOrDefault("PageSize")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "PageSize", valid_593748
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593749 = header.getOrDefault("X-Amz-Target")
  valid_593749 = validateParameter(valid_593749, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListConstraintsForPortfolio"))
  if valid_593749 != nil:
    section.add "X-Amz-Target", valid_593749
  var valid_593750 = header.getOrDefault("X-Amz-Signature")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "X-Amz-Signature", valid_593750
  var valid_593751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593751 = validateParameter(valid_593751, JString, required = false,
                                 default = nil)
  if valid_593751 != nil:
    section.add "X-Amz-Content-Sha256", valid_593751
  var valid_593752 = header.getOrDefault("X-Amz-Date")
  valid_593752 = validateParameter(valid_593752, JString, required = false,
                                 default = nil)
  if valid_593752 != nil:
    section.add "X-Amz-Date", valid_593752
  var valid_593753 = header.getOrDefault("X-Amz-Credential")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "X-Amz-Credential", valid_593753
  var valid_593754 = header.getOrDefault("X-Amz-Security-Token")
  valid_593754 = validateParameter(valid_593754, JString, required = false,
                                 default = nil)
  if valid_593754 != nil:
    section.add "X-Amz-Security-Token", valid_593754
  var valid_593755 = header.getOrDefault("X-Amz-Algorithm")
  valid_593755 = validateParameter(valid_593755, JString, required = false,
                                 default = nil)
  if valid_593755 != nil:
    section.add "X-Amz-Algorithm", valid_593755
  var valid_593756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "X-Amz-SignedHeaders", valid_593756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593758: Call_ListConstraintsForPortfolio_593744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  let valid = call_593758.validator(path, query, header, formData, body)
  let scheme = call_593758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593758.url(scheme.get, call_593758.host, call_593758.base,
                         call_593758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593758, url, valid)

proc call*(call_593759: Call_ListConstraintsForPortfolio_593744; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listConstraintsForPortfolio
  ## Lists the constraints for the specified portfolio and product.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593760 = newJObject()
  var body_593761 = newJObject()
  add(query_593760, "PageToken", newJString(PageToken))
  add(query_593760, "PageSize", newJString(PageSize))
  if body != nil:
    body_593761 = body
  result = call_593759.call(nil, query_593760, nil, nil, body_593761)

var listConstraintsForPortfolio* = Call_ListConstraintsForPortfolio_593744(
    name: "listConstraintsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio",
    validator: validate_ListConstraintsForPortfolio_593745, base: "/",
    url: url_ListConstraintsForPortfolio_593746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLaunchPaths_593762 = ref object of OpenApiRestCall_592364
proc url_ListLaunchPaths_593764(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLaunchPaths_593763(path: JsonNode; query: JsonNode;
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
  var valid_593765 = query.getOrDefault("PageToken")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = nil)
  if valid_593765 != nil:
    section.add "PageToken", valid_593765
  var valid_593766 = query.getOrDefault("PageSize")
  valid_593766 = validateParameter(valid_593766, JString, required = false,
                                 default = nil)
  if valid_593766 != nil:
    section.add "PageSize", valid_593766
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593767 = header.getOrDefault("X-Amz-Target")
  valid_593767 = validateParameter(valid_593767, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListLaunchPaths"))
  if valid_593767 != nil:
    section.add "X-Amz-Target", valid_593767
  var valid_593768 = header.getOrDefault("X-Amz-Signature")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "X-Amz-Signature", valid_593768
  var valid_593769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593769 = validateParameter(valid_593769, JString, required = false,
                                 default = nil)
  if valid_593769 != nil:
    section.add "X-Amz-Content-Sha256", valid_593769
  var valid_593770 = header.getOrDefault("X-Amz-Date")
  valid_593770 = validateParameter(valid_593770, JString, required = false,
                                 default = nil)
  if valid_593770 != nil:
    section.add "X-Amz-Date", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-Credential")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Credential", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Security-Token")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Security-Token", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Algorithm")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Algorithm", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-SignedHeaders", valid_593774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593776: Call_ListLaunchPaths_593762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  let valid = call_593776.validator(path, query, header, formData, body)
  let scheme = call_593776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593776.url(scheme.get, call_593776.host, call_593776.base,
                         call_593776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593776, url, valid)

proc call*(call_593777: Call_ListLaunchPaths_593762; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listLaunchPaths
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593778 = newJObject()
  var body_593779 = newJObject()
  add(query_593778, "PageToken", newJString(PageToken))
  add(query_593778, "PageSize", newJString(PageSize))
  if body != nil:
    body_593779 = body
  result = call_593777.call(nil, query_593778, nil, nil, body_593779)

var listLaunchPaths* = Call_ListLaunchPaths_593762(name: "listLaunchPaths",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths",
    validator: validate_ListLaunchPaths_593763, base: "/", url: url_ListLaunchPaths_593764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationPortfolioAccess_593780 = ref object of OpenApiRestCall_592364
proc url_ListOrganizationPortfolioAccess_593782(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOrganizationPortfolioAccess_593781(path: JsonNode;
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
  var valid_593783 = query.getOrDefault("PageToken")
  valid_593783 = validateParameter(valid_593783, JString, required = false,
                                 default = nil)
  if valid_593783 != nil:
    section.add "PageToken", valid_593783
  var valid_593784 = query.getOrDefault("PageSize")
  valid_593784 = validateParameter(valid_593784, JString, required = false,
                                 default = nil)
  if valid_593784 != nil:
    section.add "PageSize", valid_593784
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593785 = header.getOrDefault("X-Amz-Target")
  valid_593785 = validateParameter(valid_593785, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"))
  if valid_593785 != nil:
    section.add "X-Amz-Target", valid_593785
  var valid_593786 = header.getOrDefault("X-Amz-Signature")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "X-Amz-Signature", valid_593786
  var valid_593787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "X-Amz-Content-Sha256", valid_593787
  var valid_593788 = header.getOrDefault("X-Amz-Date")
  valid_593788 = validateParameter(valid_593788, JString, required = false,
                                 default = nil)
  if valid_593788 != nil:
    section.add "X-Amz-Date", valid_593788
  var valid_593789 = header.getOrDefault("X-Amz-Credential")
  valid_593789 = validateParameter(valid_593789, JString, required = false,
                                 default = nil)
  if valid_593789 != nil:
    section.add "X-Amz-Credential", valid_593789
  var valid_593790 = header.getOrDefault("X-Amz-Security-Token")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "X-Amz-Security-Token", valid_593790
  var valid_593791 = header.getOrDefault("X-Amz-Algorithm")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "X-Amz-Algorithm", valid_593791
  var valid_593792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593792 = validateParameter(valid_593792, JString, required = false,
                                 default = nil)
  if valid_593792 != nil:
    section.add "X-Amz-SignedHeaders", valid_593792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593794: Call_ListOrganizationPortfolioAccess_593780;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  let valid = call_593794.validator(path, query, header, formData, body)
  let scheme = call_593794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593794.url(scheme.get, call_593794.host, call_593794.base,
                         call_593794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593794, url, valid)

proc call*(call_593795: Call_ListOrganizationPortfolioAccess_593780;
          body: JsonNode; PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listOrganizationPortfolioAccess
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593796 = newJObject()
  var body_593797 = newJObject()
  add(query_593796, "PageToken", newJString(PageToken))
  add(query_593796, "PageSize", newJString(PageSize))
  if body != nil:
    body_593797 = body
  result = call_593795.call(nil, query_593796, nil, nil, body_593797)

var listOrganizationPortfolioAccess* = Call_ListOrganizationPortfolioAccess_593780(
    name: "listOrganizationPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess",
    validator: validate_ListOrganizationPortfolioAccess_593781, base: "/",
    url: url_ListOrganizationPortfolioAccess_593782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolioAccess_593798 = ref object of OpenApiRestCall_592364
proc url_ListPortfolioAccess_593800(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPortfolioAccess_593799(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593801 = header.getOrDefault("X-Amz-Target")
  valid_593801 = validateParameter(valid_593801, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolioAccess"))
  if valid_593801 != nil:
    section.add "X-Amz-Target", valid_593801
  var valid_593802 = header.getOrDefault("X-Amz-Signature")
  valid_593802 = validateParameter(valid_593802, JString, required = false,
                                 default = nil)
  if valid_593802 != nil:
    section.add "X-Amz-Signature", valid_593802
  var valid_593803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593803 = validateParameter(valid_593803, JString, required = false,
                                 default = nil)
  if valid_593803 != nil:
    section.add "X-Amz-Content-Sha256", valid_593803
  var valid_593804 = header.getOrDefault("X-Amz-Date")
  valid_593804 = validateParameter(valid_593804, JString, required = false,
                                 default = nil)
  if valid_593804 != nil:
    section.add "X-Amz-Date", valid_593804
  var valid_593805 = header.getOrDefault("X-Amz-Credential")
  valid_593805 = validateParameter(valid_593805, JString, required = false,
                                 default = nil)
  if valid_593805 != nil:
    section.add "X-Amz-Credential", valid_593805
  var valid_593806 = header.getOrDefault("X-Amz-Security-Token")
  valid_593806 = validateParameter(valid_593806, JString, required = false,
                                 default = nil)
  if valid_593806 != nil:
    section.add "X-Amz-Security-Token", valid_593806
  var valid_593807 = header.getOrDefault("X-Amz-Algorithm")
  valid_593807 = validateParameter(valid_593807, JString, required = false,
                                 default = nil)
  if valid_593807 != nil:
    section.add "X-Amz-Algorithm", valid_593807
  var valid_593808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593808 = validateParameter(valid_593808, JString, required = false,
                                 default = nil)
  if valid_593808 != nil:
    section.add "X-Amz-SignedHeaders", valid_593808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593810: Call_ListPortfolioAccess_593798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account IDs that have access to the specified portfolio.
  ## 
  let valid = call_593810.validator(path, query, header, formData, body)
  let scheme = call_593810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593810.url(scheme.get, call_593810.host, call_593810.base,
                         call_593810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593810, url, valid)

proc call*(call_593811: Call_ListPortfolioAccess_593798; body: JsonNode): Recallable =
  ## listPortfolioAccess
  ## Lists the account IDs that have access to the specified portfolio.
  ##   body: JObject (required)
  var body_593812 = newJObject()
  if body != nil:
    body_593812 = body
  result = call_593811.call(nil, nil, nil, nil, body_593812)

var listPortfolioAccess* = Call_ListPortfolioAccess_593798(
    name: "listPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess",
    validator: validate_ListPortfolioAccess_593799, base: "/",
    url: url_ListPortfolioAccess_593800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolios_593813 = ref object of OpenApiRestCall_592364
proc url_ListPortfolios_593815(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPortfolios_593814(path: JsonNode; query: JsonNode;
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
  var valid_593816 = query.getOrDefault("PageToken")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "PageToken", valid_593816
  var valid_593817 = query.getOrDefault("PageSize")
  valid_593817 = validateParameter(valid_593817, JString, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "PageSize", valid_593817
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593818 = header.getOrDefault("X-Amz-Target")
  valid_593818 = validateParameter(valid_593818, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolios"))
  if valid_593818 != nil:
    section.add "X-Amz-Target", valid_593818
  var valid_593819 = header.getOrDefault("X-Amz-Signature")
  valid_593819 = validateParameter(valid_593819, JString, required = false,
                                 default = nil)
  if valid_593819 != nil:
    section.add "X-Amz-Signature", valid_593819
  var valid_593820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "X-Amz-Content-Sha256", valid_593820
  var valid_593821 = header.getOrDefault("X-Amz-Date")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "X-Amz-Date", valid_593821
  var valid_593822 = header.getOrDefault("X-Amz-Credential")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "X-Amz-Credential", valid_593822
  var valid_593823 = header.getOrDefault("X-Amz-Security-Token")
  valid_593823 = validateParameter(valid_593823, JString, required = false,
                                 default = nil)
  if valid_593823 != nil:
    section.add "X-Amz-Security-Token", valid_593823
  var valid_593824 = header.getOrDefault("X-Amz-Algorithm")
  valid_593824 = validateParameter(valid_593824, JString, required = false,
                                 default = nil)
  if valid_593824 != nil:
    section.add "X-Amz-Algorithm", valid_593824
  var valid_593825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "X-Amz-SignedHeaders", valid_593825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593827: Call_ListPortfolios_593813; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios in the catalog.
  ## 
  let valid = call_593827.validator(path, query, header, formData, body)
  let scheme = call_593827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593827.url(scheme.get, call_593827.host, call_593827.base,
                         call_593827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593827, url, valid)

proc call*(call_593828: Call_ListPortfolios_593813; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listPortfolios
  ## Lists all portfolios in the catalog.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593829 = newJObject()
  var body_593830 = newJObject()
  add(query_593829, "PageToken", newJString(PageToken))
  add(query_593829, "PageSize", newJString(PageSize))
  if body != nil:
    body_593830 = body
  result = call_593828.call(nil, query_593829, nil, nil, body_593830)

var listPortfolios* = Call_ListPortfolios_593813(name: "listPortfolios",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios",
    validator: validate_ListPortfolios_593814, base: "/", url: url_ListPortfolios_593815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfoliosForProduct_593831 = ref object of OpenApiRestCall_592364
proc url_ListPortfoliosForProduct_593833(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPortfoliosForProduct_593832(path: JsonNode; query: JsonNode;
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
  var valid_593834 = query.getOrDefault("PageToken")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "PageToken", valid_593834
  var valid_593835 = query.getOrDefault("PageSize")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "PageSize", valid_593835
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593836 = header.getOrDefault("X-Amz-Target")
  valid_593836 = validateParameter(valid_593836, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfoliosForProduct"))
  if valid_593836 != nil:
    section.add "X-Amz-Target", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-Signature")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Signature", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Content-Sha256", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-Date")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Date", valid_593839
  var valid_593840 = header.getOrDefault("X-Amz-Credential")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-Credential", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-Security-Token")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-Security-Token", valid_593841
  var valid_593842 = header.getOrDefault("X-Amz-Algorithm")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "X-Amz-Algorithm", valid_593842
  var valid_593843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-SignedHeaders", valid_593843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593845: Call_ListPortfoliosForProduct_593831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  let valid = call_593845.validator(path, query, header, formData, body)
  let scheme = call_593845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593845.url(scheme.get, call_593845.host, call_593845.base,
                         call_593845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593845, url, valid)

proc call*(call_593846: Call_ListPortfoliosForProduct_593831; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listPortfoliosForProduct
  ## Lists all portfolios that the specified product is associated with.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593847 = newJObject()
  var body_593848 = newJObject()
  add(query_593847, "PageToken", newJString(PageToken))
  add(query_593847, "PageSize", newJString(PageSize))
  if body != nil:
    body_593848 = body
  result = call_593846.call(nil, query_593847, nil, nil, body_593848)

var listPortfoliosForProduct* = Call_ListPortfoliosForProduct_593831(
    name: "listPortfoliosForProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct",
    validator: validate_ListPortfoliosForProduct_593832, base: "/",
    url: url_ListPortfoliosForProduct_593833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipalsForPortfolio_593849 = ref object of OpenApiRestCall_592364
proc url_ListPrincipalsForPortfolio_593851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPrincipalsForPortfolio_593850(path: JsonNode; query: JsonNode;
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
  var valid_593852 = query.getOrDefault("PageToken")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "PageToken", valid_593852
  var valid_593853 = query.getOrDefault("PageSize")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "PageSize", valid_593853
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593854 = header.getOrDefault("X-Amz-Target")
  valid_593854 = validateParameter(valid_593854, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPrincipalsForPortfolio"))
  if valid_593854 != nil:
    section.add "X-Amz-Target", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Signature")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Signature", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Content-Sha256", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Date")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Date", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-Credential")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Credential", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Security-Token")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Security-Token", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Algorithm")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Algorithm", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-SignedHeaders", valid_593861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593863: Call_ListPrincipalsForPortfolio_593849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  let valid = call_593863.validator(path, query, header, formData, body)
  let scheme = call_593863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593863.url(scheme.get, call_593863.host, call_593863.base,
                         call_593863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593863, url, valid)

proc call*(call_593864: Call_ListPrincipalsForPortfolio_593849; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listPrincipalsForPortfolio
  ## Lists all principal ARNs associated with the specified portfolio.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593865 = newJObject()
  var body_593866 = newJObject()
  add(query_593865, "PageToken", newJString(PageToken))
  add(query_593865, "PageSize", newJString(PageSize))
  if body != nil:
    body_593866 = body
  result = call_593864.call(nil, query_593865, nil, nil, body_593866)

var listPrincipalsForPortfolio* = Call_ListPrincipalsForPortfolio_593849(
    name: "listPrincipalsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio",
    validator: validate_ListPrincipalsForPortfolio_593850, base: "/",
    url: url_ListPrincipalsForPortfolio_593851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedProductPlans_593867 = ref object of OpenApiRestCall_592364
proc url_ListProvisionedProductPlans_593869(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProvisionedProductPlans_593868(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593870 = header.getOrDefault("X-Amz-Target")
  valid_593870 = validateParameter(valid_593870, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisionedProductPlans"))
  if valid_593870 != nil:
    section.add "X-Amz-Target", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Signature")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Signature", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Content-Sha256", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-Date")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-Date", valid_593873
  var valid_593874 = header.getOrDefault("X-Amz-Credential")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "X-Amz-Credential", valid_593874
  var valid_593875 = header.getOrDefault("X-Amz-Security-Token")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-Security-Token", valid_593875
  var valid_593876 = header.getOrDefault("X-Amz-Algorithm")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "X-Amz-Algorithm", valid_593876
  var valid_593877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593877 = validateParameter(valid_593877, JString, required = false,
                                 default = nil)
  if valid_593877 != nil:
    section.add "X-Amz-SignedHeaders", valid_593877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593879: Call_ListProvisionedProductPlans_593867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ## 
  let valid = call_593879.validator(path, query, header, formData, body)
  let scheme = call_593879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593879.url(scheme.get, call_593879.host, call_593879.base,
                         call_593879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593879, url, valid)

proc call*(call_593880: Call_ListProvisionedProductPlans_593867; body: JsonNode): Recallable =
  ## listProvisionedProductPlans
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ##   body: JObject (required)
  var body_593881 = newJObject()
  if body != nil:
    body_593881 = body
  result = call_593880.call(nil, nil, nil, nil, body_593881)

var listProvisionedProductPlans* = Call_ListProvisionedProductPlans_593867(
    name: "listProvisionedProductPlans", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans",
    validator: validate_ListProvisionedProductPlans_593868, base: "/",
    url: url_ListProvisionedProductPlans_593869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifacts_593882 = ref object of OpenApiRestCall_592364
proc url_ListProvisioningArtifacts_593884(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProvisioningArtifacts_593883(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593885 = header.getOrDefault("X-Amz-Target")
  valid_593885 = validateParameter(valid_593885, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifacts"))
  if valid_593885 != nil:
    section.add "X-Amz-Target", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Signature")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Signature", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Content-Sha256", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Credential")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Credential", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Security-Token")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Security-Token", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Algorithm")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Algorithm", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-SignedHeaders", valid_593892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593894: Call_ListProvisioningArtifacts_593882; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ## 
  let valid = call_593894.validator(path, query, header, formData, body)
  let scheme = call_593894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593894.url(scheme.get, call_593894.host, call_593894.base,
                         call_593894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593894, url, valid)

proc call*(call_593895: Call_ListProvisioningArtifacts_593882; body: JsonNode): Recallable =
  ## listProvisioningArtifacts
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ##   body: JObject (required)
  var body_593896 = newJObject()
  if body != nil:
    body_593896 = body
  result = call_593895.call(nil, nil, nil, nil, body_593896)

var listProvisioningArtifacts* = Call_ListProvisioningArtifacts_593882(
    name: "listProvisioningArtifacts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts",
    validator: validate_ListProvisioningArtifacts_593883, base: "/",
    url: url_ListProvisioningArtifacts_593884,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifactsForServiceAction_593897 = ref object of OpenApiRestCall_592364
proc url_ListProvisioningArtifactsForServiceAction_593899(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProvisioningArtifactsForServiceAction_593898(path: JsonNode;
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
  var valid_593900 = query.getOrDefault("PageToken")
  valid_593900 = validateParameter(valid_593900, JString, required = false,
                                 default = nil)
  if valid_593900 != nil:
    section.add "PageToken", valid_593900
  var valid_593901 = query.getOrDefault("PageSize")
  valid_593901 = validateParameter(valid_593901, JString, required = false,
                                 default = nil)
  if valid_593901 != nil:
    section.add "PageSize", valid_593901
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593902 = header.getOrDefault("X-Amz-Target")
  valid_593902 = validateParameter(valid_593902, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"))
  if valid_593902 != nil:
    section.add "X-Amz-Target", valid_593902
  var valid_593903 = header.getOrDefault("X-Amz-Signature")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "X-Amz-Signature", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Date")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Date", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Credential")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Credential", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Security-Token")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Security-Token", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Algorithm")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Algorithm", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-SignedHeaders", valid_593909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593911: Call_ListProvisioningArtifactsForServiceAction_593897;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  let valid = call_593911.validator(path, query, header, formData, body)
  let scheme = call_593911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593911.url(scheme.get, call_593911.host, call_593911.base,
                         call_593911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593911, url, valid)

proc call*(call_593912: Call_ListProvisioningArtifactsForServiceAction_593897;
          body: JsonNode; PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listProvisioningArtifactsForServiceAction
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593913 = newJObject()
  var body_593914 = newJObject()
  add(query_593913, "PageToken", newJString(PageToken))
  add(query_593913, "PageSize", newJString(PageSize))
  if body != nil:
    body_593914 = body
  result = call_593912.call(nil, query_593913, nil, nil, body_593914)

var listProvisioningArtifactsForServiceAction* = Call_ListProvisioningArtifactsForServiceAction_593897(
    name: "listProvisioningArtifactsForServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction",
    validator: validate_ListProvisioningArtifactsForServiceAction_593898,
    base: "/", url: url_ListProvisioningArtifactsForServiceAction_593899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecordHistory_593915 = ref object of OpenApiRestCall_592364
proc url_ListRecordHistory_593917(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRecordHistory_593916(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593918 = header.getOrDefault("X-Amz-Target")
  valid_593918 = validateParameter(valid_593918, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListRecordHistory"))
  if valid_593918 != nil:
    section.add "X-Amz-Target", valid_593918
  var valid_593919 = header.getOrDefault("X-Amz-Signature")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "X-Amz-Signature", valid_593919
  var valid_593920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593920 = validateParameter(valid_593920, JString, required = false,
                                 default = nil)
  if valid_593920 != nil:
    section.add "X-Amz-Content-Sha256", valid_593920
  var valid_593921 = header.getOrDefault("X-Amz-Date")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "X-Amz-Date", valid_593921
  var valid_593922 = header.getOrDefault("X-Amz-Credential")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "X-Amz-Credential", valid_593922
  var valid_593923 = header.getOrDefault("X-Amz-Security-Token")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-Security-Token", valid_593923
  var valid_593924 = header.getOrDefault("X-Amz-Algorithm")
  valid_593924 = validateParameter(valid_593924, JString, required = false,
                                 default = nil)
  if valid_593924 != nil:
    section.add "X-Amz-Algorithm", valid_593924
  var valid_593925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-SignedHeaders", valid_593925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593927: Call_ListRecordHistory_593915; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified requests or all performed requests.
  ## 
  let valid = call_593927.validator(path, query, header, formData, body)
  let scheme = call_593927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593927.url(scheme.get, call_593927.host, call_593927.base,
                         call_593927.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593927, url, valid)

proc call*(call_593928: Call_ListRecordHistory_593915; body: JsonNode): Recallable =
  ## listRecordHistory
  ## Lists the specified requests or all performed requests.
  ##   body: JObject (required)
  var body_593929 = newJObject()
  if body != nil:
    body_593929 = body
  result = call_593928.call(nil, nil, nil, nil, body_593929)

var listRecordHistory* = Call_ListRecordHistory_593915(name: "listRecordHistory",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory",
    validator: validate_ListRecordHistory_593916, base: "/",
    url: url_ListRecordHistory_593917, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForTagOption_593930 = ref object of OpenApiRestCall_592364
proc url_ListResourcesForTagOption_593932(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourcesForTagOption_593931(path: JsonNode; query: JsonNode;
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
  var valid_593933 = query.getOrDefault("PageToken")
  valid_593933 = validateParameter(valid_593933, JString, required = false,
                                 default = nil)
  if valid_593933 != nil:
    section.add "PageToken", valid_593933
  var valid_593934 = query.getOrDefault("PageSize")
  valid_593934 = validateParameter(valid_593934, JString, required = false,
                                 default = nil)
  if valid_593934 != nil:
    section.add "PageSize", valid_593934
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593935 = header.getOrDefault("X-Amz-Target")
  valid_593935 = validateParameter(valid_593935, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListResourcesForTagOption"))
  if valid_593935 != nil:
    section.add "X-Amz-Target", valid_593935
  var valid_593936 = header.getOrDefault("X-Amz-Signature")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = nil)
  if valid_593936 != nil:
    section.add "X-Amz-Signature", valid_593936
  var valid_593937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "X-Amz-Content-Sha256", valid_593937
  var valid_593938 = header.getOrDefault("X-Amz-Date")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "X-Amz-Date", valid_593938
  var valid_593939 = header.getOrDefault("X-Amz-Credential")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = nil)
  if valid_593939 != nil:
    section.add "X-Amz-Credential", valid_593939
  var valid_593940 = header.getOrDefault("X-Amz-Security-Token")
  valid_593940 = validateParameter(valid_593940, JString, required = false,
                                 default = nil)
  if valid_593940 != nil:
    section.add "X-Amz-Security-Token", valid_593940
  var valid_593941 = header.getOrDefault("X-Amz-Algorithm")
  valid_593941 = validateParameter(valid_593941, JString, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "X-Amz-Algorithm", valid_593941
  var valid_593942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593942 = validateParameter(valid_593942, JString, required = false,
                                 default = nil)
  if valid_593942 != nil:
    section.add "X-Amz-SignedHeaders", valid_593942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593944: Call_ListResourcesForTagOption_593930; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources associated with the specified TagOption.
  ## 
  let valid = call_593944.validator(path, query, header, formData, body)
  let scheme = call_593944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593944.url(scheme.get, call_593944.host, call_593944.base,
                         call_593944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593944, url, valid)

proc call*(call_593945: Call_ListResourcesForTagOption_593930; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listResourcesForTagOption
  ## Lists the resources associated with the specified TagOption.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593946 = newJObject()
  var body_593947 = newJObject()
  add(query_593946, "PageToken", newJString(PageToken))
  add(query_593946, "PageSize", newJString(PageSize))
  if body != nil:
    body_593947 = body
  result = call_593945.call(nil, query_593946, nil, nil, body_593947)

var listResourcesForTagOption* = Call_ListResourcesForTagOption_593930(
    name: "listResourcesForTagOption", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption",
    validator: validate_ListResourcesForTagOption_593931, base: "/",
    url: url_ListResourcesForTagOption_593932,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActions_593948 = ref object of OpenApiRestCall_592364
proc url_ListServiceActions_593950(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListServiceActions_593949(path: JsonNode; query: JsonNode;
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
  var valid_593951 = query.getOrDefault("PageToken")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = nil)
  if valid_593951 != nil:
    section.add "PageToken", valid_593951
  var valid_593952 = query.getOrDefault("PageSize")
  valid_593952 = validateParameter(valid_593952, JString, required = false,
                                 default = nil)
  if valid_593952 != nil:
    section.add "PageSize", valid_593952
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593953 = header.getOrDefault("X-Amz-Target")
  valid_593953 = validateParameter(valid_593953, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActions"))
  if valid_593953 != nil:
    section.add "X-Amz-Target", valid_593953
  var valid_593954 = header.getOrDefault("X-Amz-Signature")
  valid_593954 = validateParameter(valid_593954, JString, required = false,
                                 default = nil)
  if valid_593954 != nil:
    section.add "X-Amz-Signature", valid_593954
  var valid_593955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593955 = validateParameter(valid_593955, JString, required = false,
                                 default = nil)
  if valid_593955 != nil:
    section.add "X-Amz-Content-Sha256", valid_593955
  var valid_593956 = header.getOrDefault("X-Amz-Date")
  valid_593956 = validateParameter(valid_593956, JString, required = false,
                                 default = nil)
  if valid_593956 != nil:
    section.add "X-Amz-Date", valid_593956
  var valid_593957 = header.getOrDefault("X-Amz-Credential")
  valid_593957 = validateParameter(valid_593957, JString, required = false,
                                 default = nil)
  if valid_593957 != nil:
    section.add "X-Amz-Credential", valid_593957
  var valid_593958 = header.getOrDefault("X-Amz-Security-Token")
  valid_593958 = validateParameter(valid_593958, JString, required = false,
                                 default = nil)
  if valid_593958 != nil:
    section.add "X-Amz-Security-Token", valid_593958
  var valid_593959 = header.getOrDefault("X-Amz-Algorithm")
  valid_593959 = validateParameter(valid_593959, JString, required = false,
                                 default = nil)
  if valid_593959 != nil:
    section.add "X-Amz-Algorithm", valid_593959
  var valid_593960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593960 = validateParameter(valid_593960, JString, required = false,
                                 default = nil)
  if valid_593960 != nil:
    section.add "X-Amz-SignedHeaders", valid_593960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593962: Call_ListServiceActions_593948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all self-service actions.
  ## 
  let valid = call_593962.validator(path, query, header, formData, body)
  let scheme = call_593962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593962.url(scheme.get, call_593962.host, call_593962.base,
                         call_593962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593962, url, valid)

proc call*(call_593963: Call_ListServiceActions_593948; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listServiceActions
  ## Lists all self-service actions.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593964 = newJObject()
  var body_593965 = newJObject()
  add(query_593964, "PageToken", newJString(PageToken))
  add(query_593964, "PageSize", newJString(PageSize))
  if body != nil:
    body_593965 = body
  result = call_593963.call(nil, query_593964, nil, nil, body_593965)

var listServiceActions* = Call_ListServiceActions_593948(
    name: "listServiceActions", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions",
    validator: validate_ListServiceActions_593949, base: "/",
    url: url_ListServiceActions_593950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActionsForProvisioningArtifact_593966 = ref object of OpenApiRestCall_592364
proc url_ListServiceActionsForProvisioningArtifact_593968(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListServiceActionsForProvisioningArtifact_593967(path: JsonNode;
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
  var valid_593969 = query.getOrDefault("PageToken")
  valid_593969 = validateParameter(valid_593969, JString, required = false,
                                 default = nil)
  if valid_593969 != nil:
    section.add "PageToken", valid_593969
  var valid_593970 = query.getOrDefault("PageSize")
  valid_593970 = validateParameter(valid_593970, JString, required = false,
                                 default = nil)
  if valid_593970 != nil:
    section.add "PageSize", valid_593970
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593971 = header.getOrDefault("X-Amz-Target")
  valid_593971 = validateParameter(valid_593971, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"))
  if valid_593971 != nil:
    section.add "X-Amz-Target", valid_593971
  var valid_593972 = header.getOrDefault("X-Amz-Signature")
  valid_593972 = validateParameter(valid_593972, JString, required = false,
                                 default = nil)
  if valid_593972 != nil:
    section.add "X-Amz-Signature", valid_593972
  var valid_593973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593973 = validateParameter(valid_593973, JString, required = false,
                                 default = nil)
  if valid_593973 != nil:
    section.add "X-Amz-Content-Sha256", valid_593973
  var valid_593974 = header.getOrDefault("X-Amz-Date")
  valid_593974 = validateParameter(valid_593974, JString, required = false,
                                 default = nil)
  if valid_593974 != nil:
    section.add "X-Amz-Date", valid_593974
  var valid_593975 = header.getOrDefault("X-Amz-Credential")
  valid_593975 = validateParameter(valid_593975, JString, required = false,
                                 default = nil)
  if valid_593975 != nil:
    section.add "X-Amz-Credential", valid_593975
  var valid_593976 = header.getOrDefault("X-Amz-Security-Token")
  valid_593976 = validateParameter(valid_593976, JString, required = false,
                                 default = nil)
  if valid_593976 != nil:
    section.add "X-Amz-Security-Token", valid_593976
  var valid_593977 = header.getOrDefault("X-Amz-Algorithm")
  valid_593977 = validateParameter(valid_593977, JString, required = false,
                                 default = nil)
  if valid_593977 != nil:
    section.add "X-Amz-Algorithm", valid_593977
  var valid_593978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593978 = validateParameter(valid_593978, JString, required = false,
                                 default = nil)
  if valid_593978 != nil:
    section.add "X-Amz-SignedHeaders", valid_593978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593980: Call_ListServiceActionsForProvisioningArtifact_593966;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  let valid = call_593980.validator(path, query, header, formData, body)
  let scheme = call_593980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593980.url(scheme.get, call_593980.host, call_593980.base,
                         call_593980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593980, url, valid)

proc call*(call_593981: Call_ListServiceActionsForProvisioningArtifact_593966;
          body: JsonNode; PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listServiceActionsForProvisioningArtifact
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_593982 = newJObject()
  var body_593983 = newJObject()
  add(query_593982, "PageToken", newJString(PageToken))
  add(query_593982, "PageSize", newJString(PageSize))
  if body != nil:
    body_593983 = body
  result = call_593981.call(nil, query_593982, nil, nil, body_593983)

var listServiceActionsForProvisioningArtifact* = Call_ListServiceActionsForProvisioningArtifact_593966(
    name: "listServiceActionsForProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact",
    validator: validate_ListServiceActionsForProvisioningArtifact_593967,
    base: "/", url: url_ListServiceActionsForProvisioningArtifact_593968,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStackInstancesForProvisionedProduct_593984 = ref object of OpenApiRestCall_592364
proc url_ListStackInstancesForProvisionedProduct_593986(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListStackInstancesForProvisionedProduct_593985(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593987 = header.getOrDefault("X-Amz-Target")
  valid_593987 = validateParameter(valid_593987, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"))
  if valid_593987 != nil:
    section.add "X-Amz-Target", valid_593987
  var valid_593988 = header.getOrDefault("X-Amz-Signature")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "X-Amz-Signature", valid_593988
  var valid_593989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "X-Amz-Content-Sha256", valid_593989
  var valid_593990 = header.getOrDefault("X-Amz-Date")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "X-Amz-Date", valid_593990
  var valid_593991 = header.getOrDefault("X-Amz-Credential")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "X-Amz-Credential", valid_593991
  var valid_593992 = header.getOrDefault("X-Amz-Security-Token")
  valid_593992 = validateParameter(valid_593992, JString, required = false,
                                 default = nil)
  if valid_593992 != nil:
    section.add "X-Amz-Security-Token", valid_593992
  var valid_593993 = header.getOrDefault("X-Amz-Algorithm")
  valid_593993 = validateParameter(valid_593993, JString, required = false,
                                 default = nil)
  if valid_593993 != nil:
    section.add "X-Amz-Algorithm", valid_593993
  var valid_593994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593994 = validateParameter(valid_593994, JString, required = false,
                                 default = nil)
  if valid_593994 != nil:
    section.add "X-Amz-SignedHeaders", valid_593994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593996: Call_ListStackInstancesForProvisionedProduct_593984;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ## 
  let valid = call_593996.validator(path, query, header, formData, body)
  let scheme = call_593996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593996.url(scheme.get, call_593996.host, call_593996.base,
                         call_593996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593996, url, valid)

proc call*(call_593997: Call_ListStackInstancesForProvisionedProduct_593984;
          body: JsonNode): Recallable =
  ## listStackInstancesForProvisionedProduct
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ##   body: JObject (required)
  var body_593998 = newJObject()
  if body != nil:
    body_593998 = body
  result = call_593997.call(nil, nil, nil, nil, body_593998)

var listStackInstancesForProvisionedProduct* = Call_ListStackInstancesForProvisionedProduct_593984(
    name: "listStackInstancesForProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct",
    validator: validate_ListStackInstancesForProvisionedProduct_593985, base: "/",
    url: url_ListStackInstancesForProvisionedProduct_593986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagOptions_593999 = ref object of OpenApiRestCall_592364
proc url_ListTagOptions_594001(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagOptions_594000(path: JsonNode; query: JsonNode;
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
  var valid_594002 = query.getOrDefault("PageToken")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "PageToken", valid_594002
  var valid_594003 = query.getOrDefault("PageSize")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "PageSize", valid_594003
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594004 = header.getOrDefault("X-Amz-Target")
  valid_594004 = validateParameter(valid_594004, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListTagOptions"))
  if valid_594004 != nil:
    section.add "X-Amz-Target", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Signature")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Signature", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Content-Sha256", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-Date")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Date", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-Credential")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Credential", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-Security-Token")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-Security-Token", valid_594009
  var valid_594010 = header.getOrDefault("X-Amz-Algorithm")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-Algorithm", valid_594010
  var valid_594011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594011 = validateParameter(valid_594011, JString, required = false,
                                 default = nil)
  if valid_594011 != nil:
    section.add "X-Amz-SignedHeaders", valid_594011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594013: Call_ListTagOptions_593999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  let valid = call_594013.validator(path, query, header, formData, body)
  let scheme = call_594013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594013.url(scheme.get, call_594013.host, call_594013.base,
                         call_594013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594013, url, valid)

proc call*(call_594014: Call_ListTagOptions_593999; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listTagOptions
  ## Lists the specified TagOptions or all TagOptions.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_594015 = newJObject()
  var body_594016 = newJObject()
  add(query_594015, "PageToken", newJString(PageToken))
  add(query_594015, "PageSize", newJString(PageSize))
  if body != nil:
    body_594016 = body
  result = call_594014.call(nil, query_594015, nil, nil, body_594016)

var listTagOptions* = Call_ListTagOptions_593999(name: "listTagOptions",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions",
    validator: validate_ListTagOptions_594000, base: "/", url: url_ListTagOptions_594001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ProvisionProduct_594017 = ref object of OpenApiRestCall_592364
proc url_ProvisionProduct_594019(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ProvisionProduct_594018(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594020 = header.getOrDefault("X-Amz-Target")
  valid_594020 = validateParameter(valid_594020, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ProvisionProduct"))
  if valid_594020 != nil:
    section.add "X-Amz-Target", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Signature")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Signature", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Content-Sha256", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-Date")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-Date", valid_594023
  var valid_594024 = header.getOrDefault("X-Amz-Credential")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-Credential", valid_594024
  var valid_594025 = header.getOrDefault("X-Amz-Security-Token")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "X-Amz-Security-Token", valid_594025
  var valid_594026 = header.getOrDefault("X-Amz-Algorithm")
  valid_594026 = validateParameter(valid_594026, JString, required = false,
                                 default = nil)
  if valid_594026 != nil:
    section.add "X-Amz-Algorithm", valid_594026
  var valid_594027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "X-Amz-SignedHeaders", valid_594027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594029: Call_ProvisionProduct_594017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ## 
  let valid = call_594029.validator(path, query, header, formData, body)
  let scheme = call_594029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594029.url(scheme.get, call_594029.host, call_594029.base,
                         call_594029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594029, url, valid)

proc call*(call_594030: Call_ProvisionProduct_594017; body: JsonNode): Recallable =
  ## provisionProduct
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ##   body: JObject (required)
  var body_594031 = newJObject()
  if body != nil:
    body_594031 = body
  result = call_594030.call(nil, nil, nil, nil, body_594031)

var provisionProduct* = Call_ProvisionProduct_594017(name: "provisionProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct",
    validator: validate_ProvisionProduct_594018, base: "/",
    url: url_ProvisionProduct_594019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectPortfolioShare_594032 = ref object of OpenApiRestCall_592364
proc url_RejectPortfolioShare_594034(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RejectPortfolioShare_594033(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594035 = header.getOrDefault("X-Amz-Target")
  valid_594035 = validateParameter(valid_594035, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.RejectPortfolioShare"))
  if valid_594035 != nil:
    section.add "X-Amz-Target", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Signature")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Signature", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Content-Sha256", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Date")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Date", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Credential")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Credential", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Security-Token")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Security-Token", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Algorithm")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Algorithm", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-SignedHeaders", valid_594042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594044: Call_RejectPortfolioShare_594032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an offer to share the specified portfolio.
  ## 
  let valid = call_594044.validator(path, query, header, formData, body)
  let scheme = call_594044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594044.url(scheme.get, call_594044.host, call_594044.base,
                         call_594044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594044, url, valid)

proc call*(call_594045: Call_RejectPortfolioShare_594032; body: JsonNode): Recallable =
  ## rejectPortfolioShare
  ## Rejects an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_594046 = newJObject()
  if body != nil:
    body_594046 = body
  result = call_594045.call(nil, nil, nil, nil, body_594046)

var rejectPortfolioShare* = Call_RejectPortfolioShare_594032(
    name: "rejectPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare",
    validator: validate_RejectPortfolioShare_594033, base: "/",
    url: url_RejectPortfolioShare_594034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScanProvisionedProducts_594047 = ref object of OpenApiRestCall_592364
proc url_ScanProvisionedProducts_594049(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ScanProvisionedProducts_594048(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594050 = header.getOrDefault("X-Amz-Target")
  valid_594050 = validateParameter(valid_594050, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ScanProvisionedProducts"))
  if valid_594050 != nil:
    section.add "X-Amz-Target", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Content-Sha256", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Date")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Date", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Credential")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Credential", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Security-Token")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Security-Token", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Algorithm")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Algorithm", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-SignedHeaders", valid_594057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594059: Call_ScanProvisionedProducts_594047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ## 
  let valid = call_594059.validator(path, query, header, formData, body)
  let scheme = call_594059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594059.url(scheme.get, call_594059.host, call_594059.base,
                         call_594059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594059, url, valid)

proc call*(call_594060: Call_ScanProvisionedProducts_594047; body: JsonNode): Recallable =
  ## scanProvisionedProducts
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ##   body: JObject (required)
  var body_594061 = newJObject()
  if body != nil:
    body_594061 = body
  result = call_594060.call(nil, nil, nil, nil, body_594061)

var scanProvisionedProducts* = Call_ScanProvisionedProducts_594047(
    name: "scanProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts",
    validator: validate_ScanProvisionedProducts_594048, base: "/",
    url: url_ScanProvisionedProducts_594049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProducts_594062 = ref object of OpenApiRestCall_592364
proc url_SearchProducts_594064(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchProducts_594063(path: JsonNode; query: JsonNode;
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
  var valid_594065 = query.getOrDefault("PageToken")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "PageToken", valid_594065
  var valid_594066 = query.getOrDefault("PageSize")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "PageSize", valid_594066
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594067 = header.getOrDefault("X-Amz-Target")
  valid_594067 = validateParameter(valid_594067, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProducts"))
  if valid_594067 != nil:
    section.add "X-Amz-Target", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Signature")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Signature", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Content-Sha256", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Date")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Date", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Credential")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Credential", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Security-Token")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Security-Token", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Algorithm")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Algorithm", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-SignedHeaders", valid_594074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594076: Call_SearchProducts_594062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products to which the caller has access.
  ## 
  let valid = call_594076.validator(path, query, header, formData, body)
  let scheme = call_594076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594076.url(scheme.get, call_594076.host, call_594076.base,
                         call_594076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594076, url, valid)

proc call*(call_594077: Call_SearchProducts_594062; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## searchProducts
  ## Gets information about the products to which the caller has access.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_594078 = newJObject()
  var body_594079 = newJObject()
  add(query_594078, "PageToken", newJString(PageToken))
  add(query_594078, "PageSize", newJString(PageSize))
  if body != nil:
    body_594079 = body
  result = call_594077.call(nil, query_594078, nil, nil, body_594079)

var searchProducts* = Call_SearchProducts_594062(name: "searchProducts",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts",
    validator: validate_SearchProducts_594063, base: "/", url: url_SearchProducts_594064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProductsAsAdmin_594080 = ref object of OpenApiRestCall_592364
proc url_SearchProductsAsAdmin_594082(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchProductsAsAdmin_594081(path: JsonNode; query: JsonNode;
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
  var valid_594083 = query.getOrDefault("PageToken")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "PageToken", valid_594083
  var valid_594084 = query.getOrDefault("PageSize")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "PageSize", valid_594084
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594085 = header.getOrDefault("X-Amz-Target")
  valid_594085 = validateParameter(valid_594085, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProductsAsAdmin"))
  if valid_594085 != nil:
    section.add "X-Amz-Target", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Signature")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Signature", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Content-Sha256", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Date")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Date", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Credential")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Credential", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Security-Token")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Security-Token", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Algorithm")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Algorithm", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-SignedHeaders", valid_594092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594094: Call_SearchProductsAsAdmin_594080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  let valid = call_594094.validator(path, query, header, formData, body)
  let scheme = call_594094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594094.url(scheme.get, call_594094.host, call_594094.base,
                         call_594094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594094, url, valid)

proc call*(call_594095: Call_SearchProductsAsAdmin_594080; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## searchProductsAsAdmin
  ## Gets information about the products for the specified portfolio or all products.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_594096 = newJObject()
  var body_594097 = newJObject()
  add(query_594096, "PageToken", newJString(PageToken))
  add(query_594096, "PageSize", newJString(PageSize))
  if body != nil:
    body_594097 = body
  result = call_594095.call(nil, query_594096, nil, nil, body_594097)

var searchProductsAsAdmin* = Call_SearchProductsAsAdmin_594080(
    name: "searchProductsAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin",
    validator: validate_SearchProductsAsAdmin_594081, base: "/",
    url: url_SearchProductsAsAdmin_594082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProvisionedProducts_594098 = ref object of OpenApiRestCall_592364
proc url_SearchProvisionedProducts_594100(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchProvisionedProducts_594099(path: JsonNode; query: JsonNode;
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
  var valid_594101 = query.getOrDefault("PageToken")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "PageToken", valid_594101
  var valid_594102 = query.getOrDefault("PageSize")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "PageSize", valid_594102
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594103 = header.getOrDefault("X-Amz-Target")
  valid_594103 = validateParameter(valid_594103, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProvisionedProducts"))
  if valid_594103 != nil:
    section.add "X-Amz-Target", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-Signature")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Signature", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Content-Sha256", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Credential")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Credential", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Security-Token")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Security-Token", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Algorithm")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Algorithm", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-SignedHeaders", valid_594110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594112: Call_SearchProvisionedProducts_594098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  let valid = call_594112.validator(path, query, header, formData, body)
  let scheme = call_594112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594112.url(scheme.get, call_594112.host, call_594112.base,
                         call_594112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594112, url, valid)

proc call*(call_594113: Call_SearchProvisionedProducts_594098; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## searchProvisionedProducts
  ## Gets information about the provisioned products that meet the specified criteria.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_594114 = newJObject()
  var body_594115 = newJObject()
  add(query_594114, "PageToken", newJString(PageToken))
  add(query_594114, "PageSize", newJString(PageSize))
  if body != nil:
    body_594115 = body
  result = call_594113.call(nil, query_594114, nil, nil, body_594115)

var searchProvisionedProducts* = Call_SearchProvisionedProducts_594098(
    name: "searchProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts",
    validator: validate_SearchProvisionedProducts_594099, base: "/",
    url: url_SearchProvisionedProducts_594100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateProvisionedProduct_594116 = ref object of OpenApiRestCall_592364
proc url_TerminateProvisionedProduct_594118(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateProvisionedProduct_594117(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594119 = header.getOrDefault("X-Amz-Target")
  valid_594119 = validateParameter(valid_594119, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.TerminateProvisionedProduct"))
  if valid_594119 != nil:
    section.add "X-Amz-Target", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Signature")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Signature", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Content-Sha256", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Date")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Date", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Credential")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Credential", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Security-Token")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Security-Token", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-SignedHeaders", valid_594126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594128: Call_TerminateProvisionedProduct_594116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_594128.validator(path, query, header, formData, body)
  let scheme = call_594128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594128.url(scheme.get, call_594128.host, call_594128.base,
                         call_594128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594128, url, valid)

proc call*(call_594129: Call_TerminateProvisionedProduct_594116; body: JsonNode): Recallable =
  ## terminateProvisionedProduct
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_594130 = newJObject()
  if body != nil:
    body_594130 = body
  result = call_594129.call(nil, nil, nil, nil, body_594130)

var terminateProvisionedProduct* = Call_TerminateProvisionedProduct_594116(
    name: "terminateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct",
    validator: validate_TerminateProvisionedProduct_594117, base: "/",
    url: url_TerminateProvisionedProduct_594118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConstraint_594131 = ref object of OpenApiRestCall_592364
proc url_UpdateConstraint_594133(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateConstraint_594132(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594134 = header.getOrDefault("X-Amz-Target")
  valid_594134 = validateParameter(valid_594134, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateConstraint"))
  if valid_594134 != nil:
    section.add "X-Amz-Target", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Signature")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Signature", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Content-Sha256", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Date")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Date", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Credential")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Credential", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Security-Token")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Security-Token", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-SignedHeaders", valid_594141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594143: Call_UpdateConstraint_594131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified constraint.
  ## 
  let valid = call_594143.validator(path, query, header, formData, body)
  let scheme = call_594143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594143.url(scheme.get, call_594143.host, call_594143.base,
                         call_594143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594143, url, valid)

proc call*(call_594144: Call_UpdateConstraint_594131; body: JsonNode): Recallable =
  ## updateConstraint
  ## Updates the specified constraint.
  ##   body: JObject (required)
  var body_594145 = newJObject()
  if body != nil:
    body_594145 = body
  result = call_594144.call(nil, nil, nil, nil, body_594145)

var updateConstraint* = Call_UpdateConstraint_594131(name: "updateConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint",
    validator: validate_UpdateConstraint_594132, base: "/",
    url: url_UpdateConstraint_594133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePortfolio_594146 = ref object of OpenApiRestCall_592364
proc url_UpdatePortfolio_594148(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePortfolio_594147(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594149 = header.getOrDefault("X-Amz-Target")
  valid_594149 = validateParameter(valid_594149, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdatePortfolio"))
  if valid_594149 != nil:
    section.add "X-Amz-Target", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Signature")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Signature", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Content-Sha256", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Date")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Date", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Credential")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Credential", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Security-Token")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Security-Token", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-SignedHeaders", valid_594156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594158: Call_UpdatePortfolio_594146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ## 
  let valid = call_594158.validator(path, query, header, formData, body)
  let scheme = call_594158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594158.url(scheme.get, call_594158.host, call_594158.base,
                         call_594158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594158, url, valid)

proc call*(call_594159: Call_UpdatePortfolio_594146; body: JsonNode): Recallable =
  ## updatePortfolio
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_594160 = newJObject()
  if body != nil:
    body_594160 = body
  result = call_594159.call(nil, nil, nil, nil, body_594160)

var updatePortfolio* = Call_UpdatePortfolio_594146(name: "updatePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio",
    validator: validate_UpdatePortfolio_594147, base: "/", url: url_UpdatePortfolio_594148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProduct_594161 = ref object of OpenApiRestCall_592364
proc url_UpdateProduct_594163(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProduct_594162(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594164 = header.getOrDefault("X-Amz-Target")
  valid_594164 = validateParameter(valid_594164, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProduct"))
  if valid_594164 != nil:
    section.add "X-Amz-Target", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Signature")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Signature", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Content-Sha256", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Date")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Date", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Credential")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Credential", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Security-Token")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Security-Token", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-SignedHeaders", valid_594171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594173: Call_UpdateProduct_594161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified product.
  ## 
  let valid = call_594173.validator(path, query, header, formData, body)
  let scheme = call_594173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594173.url(scheme.get, call_594173.host, call_594173.base,
                         call_594173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594173, url, valid)

proc call*(call_594174: Call_UpdateProduct_594161; body: JsonNode): Recallable =
  ## updateProduct
  ## Updates the specified product.
  ##   body: JObject (required)
  var body_594175 = newJObject()
  if body != nil:
    body_594175 = body
  result = call_594174.call(nil, nil, nil, nil, body_594175)

var updateProduct* = Call_UpdateProduct_594161(name: "updateProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct",
    validator: validate_UpdateProduct_594162, base: "/", url: url_UpdateProduct_594163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProduct_594176 = ref object of OpenApiRestCall_592364
proc url_UpdateProvisionedProduct_594178(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProvisionedProduct_594177(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594179 = header.getOrDefault("X-Amz-Target")
  valid_594179 = validateParameter(valid_594179, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProduct"))
  if valid_594179 != nil:
    section.add "X-Amz-Target", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Content-Sha256", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Date")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Date", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Credential")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Credential", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Security-Token")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Security-Token", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-SignedHeaders", valid_594186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594188: Call_UpdateProvisionedProduct_594176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_594188.validator(path, query, header, formData, body)
  let scheme = call_594188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594188.url(scheme.get, call_594188.host, call_594188.base,
                         call_594188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594188, url, valid)

proc call*(call_594189: Call_UpdateProvisionedProduct_594176; body: JsonNode): Recallable =
  ## updateProvisionedProduct
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_594190 = newJObject()
  if body != nil:
    body_594190 = body
  result = call_594189.call(nil, nil, nil, nil, body_594190)

var updateProvisionedProduct* = Call_UpdateProvisionedProduct_594176(
    name: "updateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct",
    validator: validate_UpdateProvisionedProduct_594177, base: "/",
    url: url_UpdateProvisionedProduct_594178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProductProperties_594191 = ref object of OpenApiRestCall_592364
proc url_UpdateProvisionedProductProperties_594193(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProvisionedProductProperties_594192(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594194 = header.getOrDefault("X-Amz-Target")
  valid_594194 = validateParameter(valid_594194, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProductProperties"))
  if valid_594194 != nil:
    section.add "X-Amz-Target", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Signature")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Signature", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Content-Sha256", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Date")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Date", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Credential")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Credential", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Security-Token")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Security-Token", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-SignedHeaders", valid_594201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594203: Call_UpdateProvisionedProductProperties_594191;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests updates to the properties of the specified provisioned product.
  ## 
  let valid = call_594203.validator(path, query, header, formData, body)
  let scheme = call_594203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594203.url(scheme.get, call_594203.host, call_594203.base,
                         call_594203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594203, url, valid)

proc call*(call_594204: Call_UpdateProvisionedProductProperties_594191;
          body: JsonNode): Recallable =
  ## updateProvisionedProductProperties
  ## Requests updates to the properties of the specified provisioned product.
  ##   body: JObject (required)
  var body_594205 = newJObject()
  if body != nil:
    body_594205 = body
  result = call_594204.call(nil, nil, nil, nil, body_594205)

var updateProvisionedProductProperties* = Call_UpdateProvisionedProductProperties_594191(
    name: "updateProvisionedProductProperties", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties",
    validator: validate_UpdateProvisionedProductProperties_594192, base: "/",
    url: url_UpdateProvisionedProductProperties_594193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisioningArtifact_594206 = ref object of OpenApiRestCall_592364
proc url_UpdateProvisioningArtifact_594208(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProvisioningArtifact_594207(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594209 = header.getOrDefault("X-Amz-Target")
  valid_594209 = validateParameter(valid_594209, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisioningArtifact"))
  if valid_594209 != nil:
    section.add "X-Amz-Target", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Signature")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Signature", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Content-Sha256", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Date")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Date", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Credential")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Credential", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Security-Token")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Security-Token", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-SignedHeaders", valid_594216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594218: Call_UpdateProvisioningArtifact_594206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_594218.validator(path, query, header, formData, body)
  let scheme = call_594218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594218.url(scheme.get, call_594218.host, call_594218.base,
                         call_594218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594218, url, valid)

proc call*(call_594219: Call_UpdateProvisioningArtifact_594206; body: JsonNode): Recallable =
  ## updateProvisioningArtifact
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_594220 = newJObject()
  if body != nil:
    body_594220 = body
  result = call_594219.call(nil, nil, nil, nil, body_594220)

var updateProvisioningArtifact* = Call_UpdateProvisioningArtifact_594206(
    name: "updateProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact",
    validator: validate_UpdateProvisioningArtifact_594207, base: "/",
    url: url_UpdateProvisioningArtifact_594208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceAction_594221 = ref object of OpenApiRestCall_592364
proc url_UpdateServiceAction_594223(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateServiceAction_594222(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594224 = header.getOrDefault("X-Amz-Target")
  valid_594224 = validateParameter(valid_594224, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateServiceAction"))
  if valid_594224 != nil:
    section.add "X-Amz-Target", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Signature")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Signature", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Content-Sha256", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Date")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Date", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Credential")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Credential", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Security-Token")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Security-Token", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-SignedHeaders", valid_594231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594233: Call_UpdateServiceAction_594221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a self-service action.
  ## 
  let valid = call_594233.validator(path, query, header, formData, body)
  let scheme = call_594233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594233.url(scheme.get, call_594233.host, call_594233.base,
                         call_594233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594233, url, valid)

proc call*(call_594234: Call_UpdateServiceAction_594221; body: JsonNode): Recallable =
  ## updateServiceAction
  ## Updates a self-service action.
  ##   body: JObject (required)
  var body_594235 = newJObject()
  if body != nil:
    body_594235 = body
  result = call_594234.call(nil, nil, nil, nil, body_594235)

var updateServiceAction* = Call_UpdateServiceAction_594221(
    name: "updateServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction",
    validator: validate_UpdateServiceAction_594222, base: "/",
    url: url_UpdateServiceAction_594223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagOption_594236 = ref object of OpenApiRestCall_592364
proc url_UpdateTagOption_594238(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTagOption_594237(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594239 = header.getOrDefault("X-Amz-Target")
  valid_594239 = validateParameter(valid_594239, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateTagOption"))
  if valid_594239 != nil:
    section.add "X-Amz-Target", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Signature")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Signature", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Content-Sha256", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Date")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Date", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Credential")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Credential", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Security-Token")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Security-Token", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-SignedHeaders", valid_594246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594248: Call_UpdateTagOption_594236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified TagOption.
  ## 
  let valid = call_594248.validator(path, query, header, formData, body)
  let scheme = call_594248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594248.url(scheme.get, call_594248.host, call_594248.base,
                         call_594248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594248, url, valid)

proc call*(call_594249: Call_UpdateTagOption_594236; body: JsonNode): Recallable =
  ## updateTagOption
  ## Updates the specified TagOption.
  ##   body: JObject (required)
  var body_594250 = newJObject()
  if body != nil:
    body_594250 = body
  result = call_594249.call(nil, nil, nil, nil, body_594250)

var updateTagOption* = Call_UpdateTagOption_594236(name: "updateTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption",
    validator: validate_UpdateTagOption_594237, base: "/", url: url_UpdateTagOption_594238,
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
