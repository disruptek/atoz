
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AcceptPortfolioShare_772933 = ref object of OpenApiRestCall_772597
proc url_AcceptPortfolioShare_772935(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AcceptPortfolioShare_772934(path: JsonNode; query: JsonNode;
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
      "AWS242ServiceCatalogService.AcceptPortfolioShare"))
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

proc call*(call_773091: Call_AcceptPortfolioShare_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an offer to share the specified portfolio.
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_AcceptPortfolioShare_772933; body: JsonNode): Recallable =
  ## acceptPortfolioShare
  ## Accepts an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var acceptPortfolioShare* = Call_AcceptPortfolioShare_772933(
    name: "acceptPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare",
    validator: validate_AcceptPortfolioShare_772934, base: "/",
    url: url_AcceptPortfolioShare_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateBudgetWithResource_773202 = ref object of OpenApiRestCall_772597
proc url_AssociateBudgetWithResource_773204(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateBudgetWithResource_773203(path: JsonNode; query: JsonNode;
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
      "AWS242ServiceCatalogService.AssociateBudgetWithResource"))
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

proc call*(call_773214: Call_AssociateBudgetWithResource_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified budget with the specified resource.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_AssociateBudgetWithResource_773202; body: JsonNode): Recallable =
  ## associateBudgetWithResource
  ## Associates the specified budget with the specified resource.
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var associateBudgetWithResource* = Call_AssociateBudgetWithResource_773202(
    name: "associateBudgetWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource",
    validator: validate_AssociateBudgetWithResource_773203, base: "/",
    url: url_AssociateBudgetWithResource_773204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePrincipalWithPortfolio_773217 = ref object of OpenApiRestCall_772597
proc url_AssociatePrincipalWithPortfolio_773219(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociatePrincipalWithPortfolio_773218(path: JsonNode;
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
      "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"))
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

proc call*(call_773229: Call_AssociatePrincipalWithPortfolio_773217;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified principal ARN with the specified portfolio.
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_AssociatePrincipalWithPortfolio_773217; body: JsonNode): Recallable =
  ## associatePrincipalWithPortfolio
  ## Associates the specified principal ARN with the specified portfolio.
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var associatePrincipalWithPortfolio* = Call_AssociatePrincipalWithPortfolio_773217(
    name: "associatePrincipalWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio",
    validator: validate_AssociatePrincipalWithPortfolio_773218, base: "/",
    url: url_AssociatePrincipalWithPortfolio_773219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateProductWithPortfolio_773232 = ref object of OpenApiRestCall_772597
proc url_AssociateProductWithPortfolio_773234(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateProductWithPortfolio_773233(path: JsonNode; query: JsonNode;
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
      "AWS242ServiceCatalogService.AssociateProductWithPortfolio"))
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

proc call*(call_773244: Call_AssociateProductWithPortfolio_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified product with the specified portfolio.
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_AssociateProductWithPortfolio_773232; body: JsonNode): Recallable =
  ## associateProductWithPortfolio
  ## Associates the specified product with the specified portfolio.
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var associateProductWithPortfolio* = Call_AssociateProductWithPortfolio_773232(
    name: "associateProductWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio",
    validator: validate_AssociateProductWithPortfolio_773233, base: "/",
    url: url_AssociateProductWithPortfolio_773234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceActionWithProvisioningArtifact_773247 = ref object of OpenApiRestCall_772597
proc url_AssociateServiceActionWithProvisioningArtifact_773249(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateServiceActionWithProvisioningArtifact_773248(
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
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString("AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"))
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

proc call*(call_773259: Call_AssociateServiceActionWithProvisioningArtifact_773247;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a self-service action with a provisioning artifact.
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_AssociateServiceActionWithProvisioningArtifact_773247;
          body: JsonNode): Recallable =
  ## associateServiceActionWithProvisioningArtifact
  ## Associates a self-service action with a provisioning artifact.
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var associateServiceActionWithProvisioningArtifact* = Call_AssociateServiceActionWithProvisioningArtifact_773247(
    name: "associateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact",
    validator: validate_AssociateServiceActionWithProvisioningArtifact_773248,
    base: "/", url: url_AssociateServiceActionWithProvisioningArtifact_773249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTagOptionWithResource_773262 = ref object of OpenApiRestCall_772597
proc url_AssociateTagOptionWithResource_773264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateTagOptionWithResource_773263(path: JsonNode;
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
      "AWS242ServiceCatalogService.AssociateTagOptionWithResource"))
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

proc call*(call_773274: Call_AssociateTagOptionWithResource_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associate the specified TagOption with the specified portfolio or product.
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_AssociateTagOptionWithResource_773262; body: JsonNode): Recallable =
  ## associateTagOptionWithResource
  ## Associate the specified TagOption with the specified portfolio or product.
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var associateTagOptionWithResource* = Call_AssociateTagOptionWithResource_773262(
    name: "associateTagOptionWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource",
    validator: validate_AssociateTagOptionWithResource_773263, base: "/",
    url: url_AssociateTagOptionWithResource_773264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateServiceActionWithProvisioningArtifact_773277 = ref object of OpenApiRestCall_772597
proc url_BatchAssociateServiceActionWithProvisioningArtifact_773279(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchAssociateServiceActionWithProvisioningArtifact_773278(
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
  valid_773282 = validateParameter(valid_773282, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"))
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

proc call*(call_773289: Call_BatchAssociateServiceActionWithProvisioningArtifact_773277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates multiple self-service actions with provisioning artifacts.
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_BatchAssociateServiceActionWithProvisioningArtifact_773277;
          body: JsonNode): Recallable =
  ## batchAssociateServiceActionWithProvisioningArtifact
  ## Associates multiple self-service actions with provisioning artifacts.
  ##   body: JObject (required)
  var body_773291 = newJObject()
  if body != nil:
    body_773291 = body
  result = call_773290.call(nil, nil, nil, nil, body_773291)

var batchAssociateServiceActionWithProvisioningArtifact* = Call_BatchAssociateServiceActionWithProvisioningArtifact_773277(
    name: "batchAssociateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact",
    validator: validate_BatchAssociateServiceActionWithProvisioningArtifact_773278,
    base: "/", url: url_BatchAssociateServiceActionWithProvisioningArtifact_773279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateServiceActionFromProvisioningArtifact_773292 = ref object of OpenApiRestCall_772597
proc url_BatchDisassociateServiceActionFromProvisioningArtifact_773294(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDisassociateServiceActionFromProvisioningArtifact_773293(
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
  valid_773297 = validateParameter(valid_773297, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"))
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

proc call*(call_773304: Call_BatchDisassociateServiceActionFromProvisioningArtifact_773292;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_BatchDisassociateServiceActionFromProvisioningArtifact_773292;
          body: JsonNode): Recallable =
  ## batchDisassociateServiceActionFromProvisioningArtifact
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var batchDisassociateServiceActionFromProvisioningArtifact* = Call_BatchDisassociateServiceActionFromProvisioningArtifact_773292(
    name: "batchDisassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact",
    validator: validate_BatchDisassociateServiceActionFromProvisioningArtifact_773293,
    base: "/", url: url_BatchDisassociateServiceActionFromProvisioningArtifact_773294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyProduct_773307 = ref object of OpenApiRestCall_772597
proc url_CopyProduct_773309(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CopyProduct_773308(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "AWS242ServiceCatalogService.CopyProduct"))
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

proc call*(call_773319: Call_CopyProduct_773307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_CopyProduct_773307; body: JsonNode): Recallable =
  ## copyProduct
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ##   body: JObject (required)
  var body_773321 = newJObject()
  if body != nil:
    body_773321 = body
  result = call_773320.call(nil, nil, nil, nil, body_773321)

var copyProduct* = Call_CopyProduct_773307(name: "copyProduct",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct",
                                        validator: validate_CopyProduct_773308,
                                        base: "/", url: url_CopyProduct_773309,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConstraint_773322 = ref object of OpenApiRestCall_772597
proc url_CreateConstraint_773324(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateConstraint_773323(path: JsonNode; query: JsonNode;
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
      "AWS242ServiceCatalogService.CreateConstraint"))
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

proc call*(call_773334: Call_CreateConstraint_773322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a constraint.
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_CreateConstraint_773322; body: JsonNode): Recallable =
  ## createConstraint
  ## Creates a constraint.
  ##   body: JObject (required)
  var body_773336 = newJObject()
  if body != nil:
    body_773336 = body
  result = call_773335.call(nil, nil, nil, nil, body_773336)

var createConstraint* = Call_CreateConstraint_773322(name: "createConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint",
    validator: validate_CreateConstraint_773323, base: "/",
    url: url_CreateConstraint_773324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolio_773337 = ref object of OpenApiRestCall_772597
proc url_CreatePortfolio_773339(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePortfolio_773338(path: JsonNode; query: JsonNode;
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
      "AWS242ServiceCatalogService.CreatePortfolio"))
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

proc call*(call_773349: Call_CreatePortfolio_773337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a portfolio.
  ## 
  let valid = call_773349.validator(path, query, header, formData, body)
  let scheme = call_773349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773349.url(scheme.get, call_773349.host, call_773349.base,
                         call_773349.route, valid.getOrDefault("path"))
  result = hook(call_773349, url, valid)

proc call*(call_773350: Call_CreatePortfolio_773337; body: JsonNode): Recallable =
  ## createPortfolio
  ## Creates a portfolio.
  ##   body: JObject (required)
  var body_773351 = newJObject()
  if body != nil:
    body_773351 = body
  result = call_773350.call(nil, nil, nil, nil, body_773351)

var createPortfolio* = Call_CreatePortfolio_773337(name: "createPortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio",
    validator: validate_CreatePortfolio_773338, base: "/", url: url_CreatePortfolio_773339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolioShare_773352 = ref object of OpenApiRestCall_772597
proc url_CreatePortfolioShare_773354(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePortfolioShare_773353(path: JsonNode; query: JsonNode;
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
  var valid_773355 = header.getOrDefault("X-Amz-Date")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Date", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Security-Token")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Security-Token", valid_773356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773357 = header.getOrDefault("X-Amz-Target")
  valid_773357 = validateParameter(valid_773357, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolioShare"))
  if valid_773357 != nil:
    section.add "X-Amz-Target", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773364: Call_CreatePortfolioShare_773352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ## 
  let valid = call_773364.validator(path, query, header, formData, body)
  let scheme = call_773364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773364.url(scheme.get, call_773364.host, call_773364.base,
                         call_773364.route, valid.getOrDefault("path"))
  result = hook(call_773364, url, valid)

proc call*(call_773365: Call_CreatePortfolioShare_773352; body: JsonNode): Recallable =
  ## createPortfolioShare
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ##   body: JObject (required)
  var body_773366 = newJObject()
  if body != nil:
    body_773366 = body
  result = call_773365.call(nil, nil, nil, nil, body_773366)

var createPortfolioShare* = Call_CreatePortfolioShare_773352(
    name: "createPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare",
    validator: validate_CreatePortfolioShare_773353, base: "/",
    url: url_CreatePortfolioShare_773354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProduct_773367 = ref object of OpenApiRestCall_772597
proc url_CreateProduct_773369(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateProduct_773368(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773370 = header.getOrDefault("X-Amz-Date")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Date", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Security-Token")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Security-Token", valid_773371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773372 = header.getOrDefault("X-Amz-Target")
  valid_773372 = validateParameter(valid_773372, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProduct"))
  if valid_773372 != nil:
    section.add "X-Amz-Target", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Content-Sha256", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Algorithm")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Algorithm", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Signature")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Signature", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-SignedHeaders", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Credential")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Credential", valid_773377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773379: Call_CreateProduct_773367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a product.
  ## 
  let valid = call_773379.validator(path, query, header, formData, body)
  let scheme = call_773379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773379.url(scheme.get, call_773379.host, call_773379.base,
                         call_773379.route, valid.getOrDefault("path"))
  result = hook(call_773379, url, valid)

proc call*(call_773380: Call_CreateProduct_773367; body: JsonNode): Recallable =
  ## createProduct
  ## Creates a product.
  ##   body: JObject (required)
  var body_773381 = newJObject()
  if body != nil:
    body_773381 = body
  result = call_773380.call(nil, nil, nil, nil, body_773381)

var createProduct* = Call_CreateProduct_773367(name: "createProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct",
    validator: validate_CreateProduct_773368, base: "/", url: url_CreateProduct_773369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisionedProductPlan_773382 = ref object of OpenApiRestCall_772597
proc url_CreateProvisionedProductPlan_773384(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateProvisionedProductPlan_773383(path: JsonNode; query: JsonNode;
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
  var valid_773385 = header.getOrDefault("X-Amz-Date")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Date", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Security-Token")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Security-Token", valid_773386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773387 = header.getOrDefault("X-Amz-Target")
  valid_773387 = validateParameter(valid_773387, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisionedProductPlan"))
  if valid_773387 != nil:
    section.add "X-Amz-Target", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Content-Sha256", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Algorithm")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Algorithm", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Signature")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Signature", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-SignedHeaders", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Credential")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Credential", valid_773392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773394: Call_CreateProvisionedProductPlan_773382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ## 
  let valid = call_773394.validator(path, query, header, formData, body)
  let scheme = call_773394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773394.url(scheme.get, call_773394.host, call_773394.base,
                         call_773394.route, valid.getOrDefault("path"))
  result = hook(call_773394, url, valid)

proc call*(call_773395: Call_CreateProvisionedProductPlan_773382; body: JsonNode): Recallable =
  ## createProvisionedProductPlan
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ##   body: JObject (required)
  var body_773396 = newJObject()
  if body != nil:
    body_773396 = body
  result = call_773395.call(nil, nil, nil, nil, body_773396)

var createProvisionedProductPlan* = Call_CreateProvisionedProductPlan_773382(
    name: "createProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan",
    validator: validate_CreateProvisionedProductPlan_773383, base: "/",
    url: url_CreateProvisionedProductPlan_773384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisioningArtifact_773397 = ref object of OpenApiRestCall_772597
proc url_CreateProvisioningArtifact_773399(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateProvisioningArtifact_773398(path: JsonNode; query: JsonNode;
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
  var valid_773400 = header.getOrDefault("X-Amz-Date")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Date", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Security-Token")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Security-Token", valid_773401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773402 = header.getOrDefault("X-Amz-Target")
  valid_773402 = validateParameter(valid_773402, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisioningArtifact"))
  if valid_773402 != nil:
    section.add "X-Amz-Target", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Content-Sha256", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Algorithm")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Algorithm", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Signature")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Signature", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-SignedHeaders", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Credential")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Credential", valid_773407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773409: Call_CreateProvisioningArtifact_773397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_773409.validator(path, query, header, formData, body)
  let scheme = call_773409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773409.url(scheme.get, call_773409.host, call_773409.base,
                         call_773409.route, valid.getOrDefault("path"))
  result = hook(call_773409, url, valid)

proc call*(call_773410: Call_CreateProvisioningArtifact_773397; body: JsonNode): Recallable =
  ## createProvisioningArtifact
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_773411 = newJObject()
  if body != nil:
    body_773411 = body
  result = call_773410.call(nil, nil, nil, nil, body_773411)

var createProvisioningArtifact* = Call_CreateProvisioningArtifact_773397(
    name: "createProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact",
    validator: validate_CreateProvisioningArtifact_773398, base: "/",
    url: url_CreateProvisioningArtifact_773399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServiceAction_773412 = ref object of OpenApiRestCall_772597
proc url_CreateServiceAction_773414(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateServiceAction_773413(path: JsonNode; query: JsonNode;
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
  var valid_773415 = header.getOrDefault("X-Amz-Date")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Date", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Security-Token")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Security-Token", valid_773416
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773417 = header.getOrDefault("X-Amz-Target")
  valid_773417 = validateParameter(valid_773417, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateServiceAction"))
  if valid_773417 != nil:
    section.add "X-Amz-Target", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Content-Sha256", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Algorithm")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Algorithm", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Signature")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Signature", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-SignedHeaders", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Credential")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Credential", valid_773422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773424: Call_CreateServiceAction_773412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a self-service action.
  ## 
  let valid = call_773424.validator(path, query, header, formData, body)
  let scheme = call_773424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773424.url(scheme.get, call_773424.host, call_773424.base,
                         call_773424.route, valid.getOrDefault("path"))
  result = hook(call_773424, url, valid)

proc call*(call_773425: Call_CreateServiceAction_773412; body: JsonNode): Recallable =
  ## createServiceAction
  ## Creates a self-service action.
  ##   body: JObject (required)
  var body_773426 = newJObject()
  if body != nil:
    body_773426 = body
  result = call_773425.call(nil, nil, nil, nil, body_773426)

var createServiceAction* = Call_CreateServiceAction_773412(
    name: "createServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction",
    validator: validate_CreateServiceAction_773413, base: "/",
    url: url_CreateServiceAction_773414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTagOption_773427 = ref object of OpenApiRestCall_772597
proc url_CreateTagOption_773429(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTagOption_773428(path: JsonNode; query: JsonNode;
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
  var valid_773430 = header.getOrDefault("X-Amz-Date")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Date", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Security-Token")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Security-Token", valid_773431
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773432 = header.getOrDefault("X-Amz-Target")
  valid_773432 = validateParameter(valid_773432, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateTagOption"))
  if valid_773432 != nil:
    section.add "X-Amz-Target", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Content-Sha256", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Algorithm")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Algorithm", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Signature")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Signature", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-SignedHeaders", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Credential")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Credential", valid_773437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773439: Call_CreateTagOption_773427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a TagOption.
  ## 
  let valid = call_773439.validator(path, query, header, formData, body)
  let scheme = call_773439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773439.url(scheme.get, call_773439.host, call_773439.base,
                         call_773439.route, valid.getOrDefault("path"))
  result = hook(call_773439, url, valid)

proc call*(call_773440: Call_CreateTagOption_773427; body: JsonNode): Recallable =
  ## createTagOption
  ## Creates a TagOption.
  ##   body: JObject (required)
  var body_773441 = newJObject()
  if body != nil:
    body_773441 = body
  result = call_773440.call(nil, nil, nil, nil, body_773441)

var createTagOption* = Call_CreateTagOption_773427(name: "createTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption",
    validator: validate_CreateTagOption_773428, base: "/", url: url_CreateTagOption_773429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConstraint_773442 = ref object of OpenApiRestCall_772597
proc url_DeleteConstraint_773444(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteConstraint_773443(path: JsonNode; query: JsonNode;
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
  var valid_773445 = header.getOrDefault("X-Amz-Date")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Date", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Security-Token")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Security-Token", valid_773446
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773447 = header.getOrDefault("X-Amz-Target")
  valid_773447 = validateParameter(valid_773447, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteConstraint"))
  if valid_773447 != nil:
    section.add "X-Amz-Target", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Content-Sha256", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Algorithm")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Algorithm", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Signature")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Signature", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-SignedHeaders", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Credential")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Credential", valid_773452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773454: Call_DeleteConstraint_773442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified constraint.
  ## 
  let valid = call_773454.validator(path, query, header, formData, body)
  let scheme = call_773454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773454.url(scheme.get, call_773454.host, call_773454.base,
                         call_773454.route, valid.getOrDefault("path"))
  result = hook(call_773454, url, valid)

proc call*(call_773455: Call_DeleteConstraint_773442; body: JsonNode): Recallable =
  ## deleteConstraint
  ## Deletes the specified constraint.
  ##   body: JObject (required)
  var body_773456 = newJObject()
  if body != nil:
    body_773456 = body
  result = call_773455.call(nil, nil, nil, nil, body_773456)

var deleteConstraint* = Call_DeleteConstraint_773442(name: "deleteConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint",
    validator: validate_DeleteConstraint_773443, base: "/",
    url: url_DeleteConstraint_773444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolio_773457 = ref object of OpenApiRestCall_772597
proc url_DeletePortfolio_773459(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeletePortfolio_773458(path: JsonNode; query: JsonNode;
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
  var valid_773460 = header.getOrDefault("X-Amz-Date")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Date", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Security-Token")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Security-Token", valid_773461
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773462 = header.getOrDefault("X-Amz-Target")
  valid_773462 = validateParameter(valid_773462, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolio"))
  if valid_773462 != nil:
    section.add "X-Amz-Target", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Content-Sha256", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Algorithm")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Algorithm", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Signature")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Signature", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-SignedHeaders", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Credential")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Credential", valid_773467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773469: Call_DeletePortfolio_773457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ## 
  let valid = call_773469.validator(path, query, header, formData, body)
  let scheme = call_773469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773469.url(scheme.get, call_773469.host, call_773469.base,
                         call_773469.route, valid.getOrDefault("path"))
  result = hook(call_773469, url, valid)

proc call*(call_773470: Call_DeletePortfolio_773457; body: JsonNode): Recallable =
  ## deletePortfolio
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ##   body: JObject (required)
  var body_773471 = newJObject()
  if body != nil:
    body_773471 = body
  result = call_773470.call(nil, nil, nil, nil, body_773471)

var deletePortfolio* = Call_DeletePortfolio_773457(name: "deletePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio",
    validator: validate_DeletePortfolio_773458, base: "/", url: url_DeletePortfolio_773459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolioShare_773472 = ref object of OpenApiRestCall_772597
proc url_DeletePortfolioShare_773474(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeletePortfolioShare_773473(path: JsonNode; query: JsonNode;
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
  var valid_773475 = header.getOrDefault("X-Amz-Date")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Date", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Security-Token")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Security-Token", valid_773476
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773477 = header.getOrDefault("X-Amz-Target")
  valid_773477 = validateParameter(valid_773477, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolioShare"))
  if valid_773477 != nil:
    section.add "X-Amz-Target", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Content-Sha256", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Algorithm")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Algorithm", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Signature")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Signature", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-SignedHeaders", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Credential")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Credential", valid_773482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773484: Call_DeletePortfolioShare_773472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ## 
  let valid = call_773484.validator(path, query, header, formData, body)
  let scheme = call_773484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773484.url(scheme.get, call_773484.host, call_773484.base,
                         call_773484.route, valid.getOrDefault("path"))
  result = hook(call_773484, url, valid)

proc call*(call_773485: Call_DeletePortfolioShare_773472; body: JsonNode): Recallable =
  ## deletePortfolioShare
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ##   body: JObject (required)
  var body_773486 = newJObject()
  if body != nil:
    body_773486 = body
  result = call_773485.call(nil, nil, nil, nil, body_773486)

var deletePortfolioShare* = Call_DeletePortfolioShare_773472(
    name: "deletePortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare",
    validator: validate_DeletePortfolioShare_773473, base: "/",
    url: url_DeletePortfolioShare_773474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProduct_773487 = ref object of OpenApiRestCall_772597
proc url_DeleteProduct_773489(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteProduct_773488(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773490 = header.getOrDefault("X-Amz-Date")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Date", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Security-Token")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Security-Token", valid_773491
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773492 = header.getOrDefault("X-Amz-Target")
  valid_773492 = validateParameter(valid_773492, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProduct"))
  if valid_773492 != nil:
    section.add "X-Amz-Target", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Content-Sha256", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Algorithm")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Algorithm", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Signature")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Signature", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-SignedHeaders", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Credential")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Credential", valid_773497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773499: Call_DeleteProduct_773487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ## 
  let valid = call_773499.validator(path, query, header, formData, body)
  let scheme = call_773499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773499.url(scheme.get, call_773499.host, call_773499.base,
                         call_773499.route, valid.getOrDefault("path"))
  result = hook(call_773499, url, valid)

proc call*(call_773500: Call_DeleteProduct_773487; body: JsonNode): Recallable =
  ## deleteProduct
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ##   body: JObject (required)
  var body_773501 = newJObject()
  if body != nil:
    body_773501 = body
  result = call_773500.call(nil, nil, nil, nil, body_773501)

var deleteProduct* = Call_DeleteProduct_773487(name: "deleteProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct",
    validator: validate_DeleteProduct_773488, base: "/", url: url_DeleteProduct_773489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedProductPlan_773502 = ref object of OpenApiRestCall_772597
proc url_DeleteProvisionedProductPlan_773504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteProvisionedProductPlan_773503(path: JsonNode; query: JsonNode;
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
  var valid_773505 = header.getOrDefault("X-Amz-Date")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Date", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Security-Token")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Security-Token", valid_773506
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773507 = header.getOrDefault("X-Amz-Target")
  valid_773507 = validateParameter(valid_773507, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisionedProductPlan"))
  if valid_773507 != nil:
    section.add "X-Amz-Target", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Content-Sha256", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Algorithm")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Algorithm", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Signature")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Signature", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-SignedHeaders", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Credential")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Credential", valid_773512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773514: Call_DeleteProvisionedProductPlan_773502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified plan.
  ## 
  let valid = call_773514.validator(path, query, header, formData, body)
  let scheme = call_773514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773514.url(scheme.get, call_773514.host, call_773514.base,
                         call_773514.route, valid.getOrDefault("path"))
  result = hook(call_773514, url, valid)

proc call*(call_773515: Call_DeleteProvisionedProductPlan_773502; body: JsonNode): Recallable =
  ## deleteProvisionedProductPlan
  ## Deletes the specified plan.
  ##   body: JObject (required)
  var body_773516 = newJObject()
  if body != nil:
    body_773516 = body
  result = call_773515.call(nil, nil, nil, nil, body_773516)

var deleteProvisionedProductPlan* = Call_DeleteProvisionedProductPlan_773502(
    name: "deleteProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan",
    validator: validate_DeleteProvisionedProductPlan_773503, base: "/",
    url: url_DeleteProvisionedProductPlan_773504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisioningArtifact_773517 = ref object of OpenApiRestCall_772597
proc url_DeleteProvisioningArtifact_773519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteProvisioningArtifact_773518(path: JsonNode; query: JsonNode;
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
  var valid_773520 = header.getOrDefault("X-Amz-Date")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Date", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Security-Token")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Security-Token", valid_773521
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773522 = header.getOrDefault("X-Amz-Target")
  valid_773522 = validateParameter(valid_773522, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisioningArtifact"))
  if valid_773522 != nil:
    section.add "X-Amz-Target", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Content-Sha256", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Algorithm")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Algorithm", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Signature")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Signature", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-SignedHeaders", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-Credential")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Credential", valid_773527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773529: Call_DeleteProvisioningArtifact_773517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ## 
  let valid = call_773529.validator(path, query, header, formData, body)
  let scheme = call_773529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773529.url(scheme.get, call_773529.host, call_773529.base,
                         call_773529.route, valid.getOrDefault("path"))
  result = hook(call_773529, url, valid)

proc call*(call_773530: Call_DeleteProvisioningArtifact_773517; body: JsonNode): Recallable =
  ## deleteProvisioningArtifact
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ##   body: JObject (required)
  var body_773531 = newJObject()
  if body != nil:
    body_773531 = body
  result = call_773530.call(nil, nil, nil, nil, body_773531)

var deleteProvisioningArtifact* = Call_DeleteProvisioningArtifact_773517(
    name: "deleteProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact",
    validator: validate_DeleteProvisioningArtifact_773518, base: "/",
    url: url_DeleteProvisioningArtifact_773519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceAction_773532 = ref object of OpenApiRestCall_772597
proc url_DeleteServiceAction_773534(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteServiceAction_773533(path: JsonNode; query: JsonNode;
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
  var valid_773535 = header.getOrDefault("X-Amz-Date")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Date", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Security-Token")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Security-Token", valid_773536
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773537 = header.getOrDefault("X-Amz-Target")
  valid_773537 = validateParameter(valid_773537, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteServiceAction"))
  if valid_773537 != nil:
    section.add "X-Amz-Target", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Content-Sha256", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Algorithm")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Algorithm", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Signature")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Signature", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-SignedHeaders", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Credential")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Credential", valid_773542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773544: Call_DeleteServiceAction_773532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a self-service action.
  ## 
  let valid = call_773544.validator(path, query, header, formData, body)
  let scheme = call_773544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773544.url(scheme.get, call_773544.host, call_773544.base,
                         call_773544.route, valid.getOrDefault("path"))
  result = hook(call_773544, url, valid)

proc call*(call_773545: Call_DeleteServiceAction_773532; body: JsonNode): Recallable =
  ## deleteServiceAction
  ## Deletes a self-service action.
  ##   body: JObject (required)
  var body_773546 = newJObject()
  if body != nil:
    body_773546 = body
  result = call_773545.call(nil, nil, nil, nil, body_773546)

var deleteServiceAction* = Call_DeleteServiceAction_773532(
    name: "deleteServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction",
    validator: validate_DeleteServiceAction_773533, base: "/",
    url: url_DeleteServiceAction_773534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagOption_773547 = ref object of OpenApiRestCall_772597
proc url_DeleteTagOption_773549(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTagOption_773548(path: JsonNode; query: JsonNode;
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
  var valid_773550 = header.getOrDefault("X-Amz-Date")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Date", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Security-Token")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Security-Token", valid_773551
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773552 = header.getOrDefault("X-Amz-Target")
  valid_773552 = validateParameter(valid_773552, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteTagOption"))
  if valid_773552 != nil:
    section.add "X-Amz-Target", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Content-Sha256", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Algorithm")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Algorithm", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Signature")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Signature", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-SignedHeaders", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Credential")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Credential", valid_773557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773559: Call_DeleteTagOption_773547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ## 
  let valid = call_773559.validator(path, query, header, formData, body)
  let scheme = call_773559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773559.url(scheme.get, call_773559.host, call_773559.base,
                         call_773559.route, valid.getOrDefault("path"))
  result = hook(call_773559, url, valid)

proc call*(call_773560: Call_DeleteTagOption_773547; body: JsonNode): Recallable =
  ## deleteTagOption
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ##   body: JObject (required)
  var body_773561 = newJObject()
  if body != nil:
    body_773561 = body
  result = call_773560.call(nil, nil, nil, nil, body_773561)

var deleteTagOption* = Call_DeleteTagOption_773547(name: "deleteTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption",
    validator: validate_DeleteTagOption_773548, base: "/", url: url_DeleteTagOption_773549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConstraint_773562 = ref object of OpenApiRestCall_772597
proc url_DescribeConstraint_773564(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeConstraint_773563(path: JsonNode; query: JsonNode;
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
  var valid_773565 = header.getOrDefault("X-Amz-Date")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Date", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Security-Token")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Security-Token", valid_773566
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773567 = header.getOrDefault("X-Amz-Target")
  valid_773567 = validateParameter(valid_773567, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeConstraint"))
  if valid_773567 != nil:
    section.add "X-Amz-Target", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Content-Sha256", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Algorithm")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Algorithm", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Signature")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Signature", valid_773570
  var valid_773571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-SignedHeaders", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Credential")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Credential", valid_773572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773574: Call_DescribeConstraint_773562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified constraint.
  ## 
  let valid = call_773574.validator(path, query, header, formData, body)
  let scheme = call_773574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773574.url(scheme.get, call_773574.host, call_773574.base,
                         call_773574.route, valid.getOrDefault("path"))
  result = hook(call_773574, url, valid)

proc call*(call_773575: Call_DescribeConstraint_773562; body: JsonNode): Recallable =
  ## describeConstraint
  ## Gets information about the specified constraint.
  ##   body: JObject (required)
  var body_773576 = newJObject()
  if body != nil:
    body_773576 = body
  result = call_773575.call(nil, nil, nil, nil, body_773576)

var describeConstraint* = Call_DescribeConstraint_773562(
    name: "describeConstraint", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint",
    validator: validate_DescribeConstraint_773563, base: "/",
    url: url_DescribeConstraint_773564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyProductStatus_773577 = ref object of OpenApiRestCall_772597
proc url_DescribeCopyProductStatus_773579(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCopyProductStatus_773578(path: JsonNode; query: JsonNode;
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
  var valid_773580 = header.getOrDefault("X-Amz-Date")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Date", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Security-Token")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Security-Token", valid_773581
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773582 = header.getOrDefault("X-Amz-Target")
  valid_773582 = validateParameter(valid_773582, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeCopyProductStatus"))
  if valid_773582 != nil:
    section.add "X-Amz-Target", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Content-Sha256", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Algorithm")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Algorithm", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Signature")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Signature", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-SignedHeaders", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Credential")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Credential", valid_773587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773589: Call_DescribeCopyProductStatus_773577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified copy product operation.
  ## 
  let valid = call_773589.validator(path, query, header, formData, body)
  let scheme = call_773589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773589.url(scheme.get, call_773589.host, call_773589.base,
                         call_773589.route, valid.getOrDefault("path"))
  result = hook(call_773589, url, valid)

proc call*(call_773590: Call_DescribeCopyProductStatus_773577; body: JsonNode): Recallable =
  ## describeCopyProductStatus
  ## Gets the status of the specified copy product operation.
  ##   body: JObject (required)
  var body_773591 = newJObject()
  if body != nil:
    body_773591 = body
  result = call_773590.call(nil, nil, nil, nil, body_773591)

var describeCopyProductStatus* = Call_DescribeCopyProductStatus_773577(
    name: "describeCopyProductStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus",
    validator: validate_DescribeCopyProductStatus_773578, base: "/",
    url: url_DescribeCopyProductStatus_773579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolio_773592 = ref object of OpenApiRestCall_772597
proc url_DescribePortfolio_773594(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePortfolio_773593(path: JsonNode; query: JsonNode;
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
  var valid_773595 = header.getOrDefault("X-Amz-Date")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Date", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Security-Token")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Security-Token", valid_773596
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773597 = header.getOrDefault("X-Amz-Target")
  valid_773597 = validateParameter(valid_773597, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolio"))
  if valid_773597 != nil:
    section.add "X-Amz-Target", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Content-Sha256", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Algorithm")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Algorithm", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Signature")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Signature", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-SignedHeaders", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Credential")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Credential", valid_773602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773604: Call_DescribePortfolio_773592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified portfolio.
  ## 
  let valid = call_773604.validator(path, query, header, formData, body)
  let scheme = call_773604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773604.url(scheme.get, call_773604.host, call_773604.base,
                         call_773604.route, valid.getOrDefault("path"))
  result = hook(call_773604, url, valid)

proc call*(call_773605: Call_DescribePortfolio_773592; body: JsonNode): Recallable =
  ## describePortfolio
  ## Gets information about the specified portfolio.
  ##   body: JObject (required)
  var body_773606 = newJObject()
  if body != nil:
    body_773606 = body
  result = call_773605.call(nil, nil, nil, nil, body_773606)

var describePortfolio* = Call_DescribePortfolio_773592(name: "describePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio",
    validator: validate_DescribePortfolio_773593, base: "/",
    url: url_DescribePortfolio_773594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolioShareStatus_773607 = ref object of OpenApiRestCall_772597
proc url_DescribePortfolioShareStatus_773609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePortfolioShareStatus_773608(path: JsonNode; query: JsonNode;
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
  var valid_773610 = header.getOrDefault("X-Amz-Date")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Date", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Security-Token")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Security-Token", valid_773611
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773612 = header.getOrDefault("X-Amz-Target")
  valid_773612 = validateParameter(valid_773612, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolioShareStatus"))
  if valid_773612 != nil:
    section.add "X-Amz-Target", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Content-Sha256", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Algorithm")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Algorithm", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Signature")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Signature", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-SignedHeaders", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Credential")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Credential", valid_773617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773619: Call_DescribePortfolioShareStatus_773607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ## 
  let valid = call_773619.validator(path, query, header, formData, body)
  let scheme = call_773619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773619.url(scheme.get, call_773619.host, call_773619.base,
                         call_773619.route, valid.getOrDefault("path"))
  result = hook(call_773619, url, valid)

proc call*(call_773620: Call_DescribePortfolioShareStatus_773607; body: JsonNode): Recallable =
  ## describePortfolioShareStatus
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_773621 = newJObject()
  if body != nil:
    body_773621 = body
  result = call_773620.call(nil, nil, nil, nil, body_773621)

var describePortfolioShareStatus* = Call_DescribePortfolioShareStatus_773607(
    name: "describePortfolioShareStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus",
    validator: validate_DescribePortfolioShareStatus_773608, base: "/",
    url: url_DescribePortfolioShareStatus_773609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProduct_773622 = ref object of OpenApiRestCall_772597
proc url_DescribeProduct_773624(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProduct_773623(path: JsonNode; query: JsonNode;
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
  var valid_773625 = header.getOrDefault("X-Amz-Date")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Date", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Security-Token")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Security-Token", valid_773626
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773627 = header.getOrDefault("X-Amz-Target")
  valid_773627 = validateParameter(valid_773627, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProduct"))
  if valid_773627 != nil:
    section.add "X-Amz-Target", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Content-Sha256", valid_773628
  var valid_773629 = header.getOrDefault("X-Amz-Algorithm")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Algorithm", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Signature")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Signature", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-SignedHeaders", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Credential")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Credential", valid_773632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773634: Call_DescribeProduct_773622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_773634.validator(path, query, header, formData, body)
  let scheme = call_773634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773634.url(scheme.get, call_773634.host, call_773634.base,
                         call_773634.route, valid.getOrDefault("path"))
  result = hook(call_773634, url, valid)

proc call*(call_773635: Call_DescribeProduct_773622; body: JsonNode): Recallable =
  ## describeProduct
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_773636 = newJObject()
  if body != nil:
    body_773636 = body
  result = call_773635.call(nil, nil, nil, nil, body_773636)

var describeProduct* = Call_DescribeProduct_773622(name: "describeProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct",
    validator: validate_DescribeProduct_773623, base: "/", url: url_DescribeProduct_773624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductAsAdmin_773637 = ref object of OpenApiRestCall_772597
proc url_DescribeProductAsAdmin_773639(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProductAsAdmin_773638(path: JsonNode; query: JsonNode;
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
  var valid_773640 = header.getOrDefault("X-Amz-Date")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Date", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Security-Token")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Security-Token", valid_773641
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773642 = header.getOrDefault("X-Amz-Target")
  valid_773642 = validateParameter(valid_773642, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductAsAdmin"))
  if valid_773642 != nil:
    section.add "X-Amz-Target", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Content-Sha256", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Algorithm")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Algorithm", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Signature")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Signature", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-SignedHeaders", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Credential")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Credential", valid_773647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773649: Call_DescribeProductAsAdmin_773637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product. This operation is run with administrator access.
  ## 
  let valid = call_773649.validator(path, query, header, formData, body)
  let scheme = call_773649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773649.url(scheme.get, call_773649.host, call_773649.base,
                         call_773649.route, valid.getOrDefault("path"))
  result = hook(call_773649, url, valid)

proc call*(call_773650: Call_DescribeProductAsAdmin_773637; body: JsonNode): Recallable =
  ## describeProductAsAdmin
  ## Gets information about the specified product. This operation is run with administrator access.
  ##   body: JObject (required)
  var body_773651 = newJObject()
  if body != nil:
    body_773651 = body
  result = call_773650.call(nil, nil, nil, nil, body_773651)

var describeProductAsAdmin* = Call_DescribeProductAsAdmin_773637(
    name: "describeProductAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin",
    validator: validate_DescribeProductAsAdmin_773638, base: "/",
    url: url_DescribeProductAsAdmin_773639, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductView_773652 = ref object of OpenApiRestCall_772597
proc url_DescribeProductView_773654(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProductView_773653(path: JsonNode; query: JsonNode;
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
  var valid_773655 = header.getOrDefault("X-Amz-Date")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Date", valid_773655
  var valid_773656 = header.getOrDefault("X-Amz-Security-Token")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Security-Token", valid_773656
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773657 = header.getOrDefault("X-Amz-Target")
  valid_773657 = validateParameter(valid_773657, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductView"))
  if valid_773657 != nil:
    section.add "X-Amz-Target", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Content-Sha256", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Algorithm")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Algorithm", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Signature")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Signature", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-SignedHeaders", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Credential")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Credential", valid_773662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773664: Call_DescribeProductView_773652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_773664.validator(path, query, header, formData, body)
  let scheme = call_773664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773664.url(scheme.get, call_773664.host, call_773664.base,
                         call_773664.route, valid.getOrDefault("path"))
  result = hook(call_773664, url, valid)

proc call*(call_773665: Call_DescribeProductView_773652; body: JsonNode): Recallable =
  ## describeProductView
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_773666 = newJObject()
  if body != nil:
    body_773666 = body
  result = call_773665.call(nil, nil, nil, nil, body_773666)

var describeProductView* = Call_DescribeProductView_773652(
    name: "describeProductView", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView",
    validator: validate_DescribeProductView_773653, base: "/",
    url: url_DescribeProductView_773654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProduct_773667 = ref object of OpenApiRestCall_772597
proc url_DescribeProvisionedProduct_773669(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProvisionedProduct_773668(path: JsonNode; query: JsonNode;
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
  var valid_773670 = header.getOrDefault("X-Amz-Date")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Date", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-Security-Token")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Security-Token", valid_773671
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773672 = header.getOrDefault("X-Amz-Target")
  valid_773672 = validateParameter(valid_773672, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProduct"))
  if valid_773672 != nil:
    section.add "X-Amz-Target", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-Content-Sha256", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Algorithm")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Algorithm", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Signature")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Signature", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-SignedHeaders", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Credential")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Credential", valid_773677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773679: Call_DescribeProvisionedProduct_773667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioned product.
  ## 
  let valid = call_773679.validator(path, query, header, formData, body)
  let scheme = call_773679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773679.url(scheme.get, call_773679.host, call_773679.base,
                         call_773679.route, valid.getOrDefault("path"))
  result = hook(call_773679, url, valid)

proc call*(call_773680: Call_DescribeProvisionedProduct_773667; body: JsonNode): Recallable =
  ## describeProvisionedProduct
  ## Gets information about the specified provisioned product.
  ##   body: JObject (required)
  var body_773681 = newJObject()
  if body != nil:
    body_773681 = body
  result = call_773680.call(nil, nil, nil, nil, body_773681)

var describeProvisionedProduct* = Call_DescribeProvisionedProduct_773667(
    name: "describeProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct",
    validator: validate_DescribeProvisionedProduct_773668, base: "/",
    url: url_DescribeProvisionedProduct_773669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProductPlan_773682 = ref object of OpenApiRestCall_772597
proc url_DescribeProvisionedProductPlan_773684(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProvisionedProductPlan_773683(path: JsonNode;
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
  var valid_773685 = header.getOrDefault("X-Amz-Date")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-Date", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-Security-Token")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Security-Token", valid_773686
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773687 = header.getOrDefault("X-Amz-Target")
  valid_773687 = validateParameter(valid_773687, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProductPlan"))
  if valid_773687 != nil:
    section.add "X-Amz-Target", valid_773687
  var valid_773688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-Content-Sha256", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Algorithm")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Algorithm", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Signature")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Signature", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-SignedHeaders", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Credential")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Credential", valid_773692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773694: Call_DescribeProvisionedProductPlan_773682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the resource changes for the specified plan.
  ## 
  let valid = call_773694.validator(path, query, header, formData, body)
  let scheme = call_773694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773694.url(scheme.get, call_773694.host, call_773694.base,
                         call_773694.route, valid.getOrDefault("path"))
  result = hook(call_773694, url, valid)

proc call*(call_773695: Call_DescribeProvisionedProductPlan_773682; body: JsonNode): Recallable =
  ## describeProvisionedProductPlan
  ## Gets information about the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_773696 = newJObject()
  if body != nil:
    body_773696 = body
  result = call_773695.call(nil, nil, nil, nil, body_773696)

var describeProvisionedProductPlan* = Call_DescribeProvisionedProductPlan_773682(
    name: "describeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan",
    validator: validate_DescribeProvisionedProductPlan_773683, base: "/",
    url: url_DescribeProvisionedProductPlan_773684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningArtifact_773697 = ref object of OpenApiRestCall_772597
proc url_DescribeProvisioningArtifact_773699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProvisioningArtifact_773698(path: JsonNode; query: JsonNode;
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
  var valid_773700 = header.getOrDefault("X-Amz-Date")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-Date", valid_773700
  var valid_773701 = header.getOrDefault("X-Amz-Security-Token")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Security-Token", valid_773701
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773702 = header.getOrDefault("X-Amz-Target")
  valid_773702 = validateParameter(valid_773702, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningArtifact"))
  if valid_773702 != nil:
    section.add "X-Amz-Target", valid_773702
  var valid_773703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-Content-Sha256", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-Algorithm")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Algorithm", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Signature")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Signature", valid_773705
  var valid_773706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-SignedHeaders", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Credential")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Credential", valid_773707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773709: Call_DescribeProvisioningArtifact_773697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ## 
  let valid = call_773709.validator(path, query, header, formData, body)
  let scheme = call_773709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773709.url(scheme.get, call_773709.host, call_773709.base,
                         call_773709.route, valid.getOrDefault("path"))
  result = hook(call_773709, url, valid)

proc call*(call_773710: Call_DescribeProvisioningArtifact_773697; body: JsonNode): Recallable =
  ## describeProvisioningArtifact
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ##   body: JObject (required)
  var body_773711 = newJObject()
  if body != nil:
    body_773711 = body
  result = call_773710.call(nil, nil, nil, nil, body_773711)

var describeProvisioningArtifact* = Call_DescribeProvisioningArtifact_773697(
    name: "describeProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact",
    validator: validate_DescribeProvisioningArtifact_773698, base: "/",
    url: url_DescribeProvisioningArtifact_773699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningParameters_773712 = ref object of OpenApiRestCall_772597
proc url_DescribeProvisioningParameters_773714(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProvisioningParameters_773713(path: JsonNode;
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
  var valid_773715 = header.getOrDefault("X-Amz-Date")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Date", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-Security-Token")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Security-Token", valid_773716
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773717 = header.getOrDefault("X-Amz-Target")
  valid_773717 = validateParameter(valid_773717, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningParameters"))
  if valid_773717 != nil:
    section.add "X-Amz-Target", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-Content-Sha256", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-Algorithm")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Algorithm", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Signature")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Signature", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-SignedHeaders", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-Credential")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Credential", valid_773722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773724: Call_DescribeProvisioningParameters_773712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ## 
  let valid = call_773724.validator(path, query, header, formData, body)
  let scheme = call_773724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773724.url(scheme.get, call_773724.host, call_773724.base,
                         call_773724.route, valid.getOrDefault("path"))
  result = hook(call_773724, url, valid)

proc call*(call_773725: Call_DescribeProvisioningParameters_773712; body: JsonNode): Recallable =
  ## describeProvisioningParameters
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ##   body: JObject (required)
  var body_773726 = newJObject()
  if body != nil:
    body_773726 = body
  result = call_773725.call(nil, nil, nil, nil, body_773726)

var describeProvisioningParameters* = Call_DescribeProvisioningParameters_773712(
    name: "describeProvisioningParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters",
    validator: validate_DescribeProvisioningParameters_773713, base: "/",
    url: url_DescribeProvisioningParameters_773714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecord_773727 = ref object of OpenApiRestCall_772597
proc url_DescribeRecord_773729(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRecord_773728(path: JsonNode; query: JsonNode;
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
  var valid_773730 = header.getOrDefault("X-Amz-Date")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Date", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Security-Token")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Security-Token", valid_773731
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773732 = header.getOrDefault("X-Amz-Target")
  valid_773732 = validateParameter(valid_773732, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeRecord"))
  if valid_773732 != nil:
    section.add "X-Amz-Target", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Content-Sha256", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Algorithm")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Algorithm", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-Signature")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-Signature", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-SignedHeaders", valid_773736
  var valid_773737 = header.getOrDefault("X-Amz-Credential")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Credential", valid_773737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773739: Call_DescribeRecord_773727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ## 
  let valid = call_773739.validator(path, query, header, formData, body)
  let scheme = call_773739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773739.url(scheme.get, call_773739.host, call_773739.base,
                         call_773739.route, valid.getOrDefault("path"))
  result = hook(call_773739, url, valid)

proc call*(call_773740: Call_DescribeRecord_773727; body: JsonNode): Recallable =
  ## describeRecord
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ##   body: JObject (required)
  var body_773741 = newJObject()
  if body != nil:
    body_773741 = body
  result = call_773740.call(nil, nil, nil, nil, body_773741)

var describeRecord* = Call_DescribeRecord_773727(name: "describeRecord",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord",
    validator: validate_DescribeRecord_773728, base: "/", url: url_DescribeRecord_773729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceAction_773742 = ref object of OpenApiRestCall_772597
proc url_DescribeServiceAction_773744(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeServiceAction_773743(path: JsonNode; query: JsonNode;
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
  var valid_773745 = header.getOrDefault("X-Amz-Date")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Date", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-Security-Token")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Security-Token", valid_773746
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773747 = header.getOrDefault("X-Amz-Target")
  valid_773747 = validateParameter(valid_773747, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceAction"))
  if valid_773747 != nil:
    section.add "X-Amz-Target", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Content-Sha256", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Algorithm")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Algorithm", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-Signature")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Signature", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-SignedHeaders", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-Credential")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Credential", valid_773752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773754: Call_DescribeServiceAction_773742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a self-service action.
  ## 
  let valid = call_773754.validator(path, query, header, formData, body)
  let scheme = call_773754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773754.url(scheme.get, call_773754.host, call_773754.base,
                         call_773754.route, valid.getOrDefault("path"))
  result = hook(call_773754, url, valid)

proc call*(call_773755: Call_DescribeServiceAction_773742; body: JsonNode): Recallable =
  ## describeServiceAction
  ## Describes a self-service action.
  ##   body: JObject (required)
  var body_773756 = newJObject()
  if body != nil:
    body_773756 = body
  result = call_773755.call(nil, nil, nil, nil, body_773756)

var describeServiceAction* = Call_DescribeServiceAction_773742(
    name: "describeServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction",
    validator: validate_DescribeServiceAction_773743, base: "/",
    url: url_DescribeServiceAction_773744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceActionExecutionParameters_773757 = ref object of OpenApiRestCall_772597
proc url_DescribeServiceActionExecutionParameters_773759(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeServiceActionExecutionParameters_773758(path: JsonNode;
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
  var valid_773760 = header.getOrDefault("X-Amz-Date")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Date", valid_773760
  var valid_773761 = header.getOrDefault("X-Amz-Security-Token")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-Security-Token", valid_773761
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773762 = header.getOrDefault("X-Amz-Target")
  valid_773762 = validateParameter(valid_773762, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"))
  if valid_773762 != nil:
    section.add "X-Amz-Target", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Content-Sha256", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Algorithm")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Algorithm", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-Signature")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-Signature", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-SignedHeaders", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-Credential")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-Credential", valid_773767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773769: Call_DescribeServiceActionExecutionParameters_773757;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_773769.validator(path, query, header, formData, body)
  let scheme = call_773769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773769.url(scheme.get, call_773769.host, call_773769.base,
                         call_773769.route, valid.getOrDefault("path"))
  result = hook(call_773769, url, valid)

proc call*(call_773770: Call_DescribeServiceActionExecutionParameters_773757;
          body: JsonNode): Recallable =
  ## describeServiceActionExecutionParameters
  ##   body: JObject (required)
  var body_773771 = newJObject()
  if body != nil:
    body_773771 = body
  result = call_773770.call(nil, nil, nil, nil, body_773771)

var describeServiceActionExecutionParameters* = Call_DescribeServiceActionExecutionParameters_773757(
    name: "describeServiceActionExecutionParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters",
    validator: validate_DescribeServiceActionExecutionParameters_773758,
    base: "/", url: url_DescribeServiceActionExecutionParameters_773759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTagOption_773772 = ref object of OpenApiRestCall_772597
proc url_DescribeTagOption_773774(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTagOption_773773(path: JsonNode; query: JsonNode;
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
  var valid_773775 = header.getOrDefault("X-Amz-Date")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-Date", valid_773775
  var valid_773776 = header.getOrDefault("X-Amz-Security-Token")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Security-Token", valid_773776
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773777 = header.getOrDefault("X-Amz-Target")
  valid_773777 = validateParameter(valid_773777, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeTagOption"))
  if valid_773777 != nil:
    section.add "X-Amz-Target", valid_773777
  var valid_773778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773778 = validateParameter(valid_773778, JString, required = false,
                                 default = nil)
  if valid_773778 != nil:
    section.add "X-Amz-Content-Sha256", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Algorithm")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Algorithm", valid_773779
  var valid_773780 = header.getOrDefault("X-Amz-Signature")
  valid_773780 = validateParameter(valid_773780, JString, required = false,
                                 default = nil)
  if valid_773780 != nil:
    section.add "X-Amz-Signature", valid_773780
  var valid_773781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-SignedHeaders", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-Credential")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Credential", valid_773782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773784: Call_DescribeTagOption_773772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified TagOption.
  ## 
  let valid = call_773784.validator(path, query, header, formData, body)
  let scheme = call_773784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773784.url(scheme.get, call_773784.host, call_773784.base,
                         call_773784.route, valid.getOrDefault("path"))
  result = hook(call_773784, url, valid)

proc call*(call_773785: Call_DescribeTagOption_773772; body: JsonNode): Recallable =
  ## describeTagOption
  ## Gets information about the specified TagOption.
  ##   body: JObject (required)
  var body_773786 = newJObject()
  if body != nil:
    body_773786 = body
  result = call_773785.call(nil, nil, nil, nil, body_773786)

var describeTagOption* = Call_DescribeTagOption_773772(name: "describeTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption",
    validator: validate_DescribeTagOption_773773, base: "/",
    url: url_DescribeTagOption_773774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSOrganizationsAccess_773787 = ref object of OpenApiRestCall_772597
proc url_DisableAWSOrganizationsAccess_773789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableAWSOrganizationsAccess_773788(path: JsonNode; query: JsonNode;
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
  var valid_773790 = header.getOrDefault("X-Amz-Date")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Date", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-Security-Token")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Security-Token", valid_773791
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773792 = header.getOrDefault("X-Amz-Target")
  valid_773792 = validateParameter(valid_773792, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"))
  if valid_773792 != nil:
    section.add "X-Amz-Target", valid_773792
  var valid_773793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-Content-Sha256", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Algorithm")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Algorithm", valid_773794
  var valid_773795 = header.getOrDefault("X-Amz-Signature")
  valid_773795 = validateParameter(valid_773795, JString, required = false,
                                 default = nil)
  if valid_773795 != nil:
    section.add "X-Amz-Signature", valid_773795
  var valid_773796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-SignedHeaders", valid_773796
  var valid_773797 = header.getOrDefault("X-Amz-Credential")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Credential", valid_773797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773799: Call_DisableAWSOrganizationsAccess_773787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ## 
  let valid = call_773799.validator(path, query, header, formData, body)
  let scheme = call_773799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773799.url(scheme.get, call_773799.host, call_773799.base,
                         call_773799.route, valid.getOrDefault("path"))
  result = hook(call_773799, url, valid)

proc call*(call_773800: Call_DisableAWSOrganizationsAccess_773787; body: JsonNode): Recallable =
  ## disableAWSOrganizationsAccess
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_773801 = newJObject()
  if body != nil:
    body_773801 = body
  result = call_773800.call(nil, nil, nil, nil, body_773801)

var disableAWSOrganizationsAccess* = Call_DisableAWSOrganizationsAccess_773787(
    name: "disableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess",
    validator: validate_DisableAWSOrganizationsAccess_773788, base: "/",
    url: url_DisableAWSOrganizationsAccess_773789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateBudgetFromResource_773802 = ref object of OpenApiRestCall_772597
proc url_DisassociateBudgetFromResource_773804(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateBudgetFromResource_773803(path: JsonNode;
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
  var valid_773805 = header.getOrDefault("X-Amz-Date")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-Date", valid_773805
  var valid_773806 = header.getOrDefault("X-Amz-Security-Token")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-Security-Token", valid_773806
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773807 = header.getOrDefault("X-Amz-Target")
  valid_773807 = validateParameter(valid_773807, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateBudgetFromResource"))
  if valid_773807 != nil:
    section.add "X-Amz-Target", valid_773807
  var valid_773808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "X-Amz-Content-Sha256", valid_773808
  var valid_773809 = header.getOrDefault("X-Amz-Algorithm")
  valid_773809 = validateParameter(valid_773809, JString, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "X-Amz-Algorithm", valid_773809
  var valid_773810 = header.getOrDefault("X-Amz-Signature")
  valid_773810 = validateParameter(valid_773810, JString, required = false,
                                 default = nil)
  if valid_773810 != nil:
    section.add "X-Amz-Signature", valid_773810
  var valid_773811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773811 = validateParameter(valid_773811, JString, required = false,
                                 default = nil)
  if valid_773811 != nil:
    section.add "X-Amz-SignedHeaders", valid_773811
  var valid_773812 = header.getOrDefault("X-Amz-Credential")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Credential", valid_773812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773814: Call_DisassociateBudgetFromResource_773802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified budget from the specified resource.
  ## 
  let valid = call_773814.validator(path, query, header, formData, body)
  let scheme = call_773814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773814.url(scheme.get, call_773814.host, call_773814.base,
                         call_773814.route, valid.getOrDefault("path"))
  result = hook(call_773814, url, valid)

proc call*(call_773815: Call_DisassociateBudgetFromResource_773802; body: JsonNode): Recallable =
  ## disassociateBudgetFromResource
  ## Disassociates the specified budget from the specified resource.
  ##   body: JObject (required)
  var body_773816 = newJObject()
  if body != nil:
    body_773816 = body
  result = call_773815.call(nil, nil, nil, nil, body_773816)

var disassociateBudgetFromResource* = Call_DisassociateBudgetFromResource_773802(
    name: "disassociateBudgetFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource",
    validator: validate_DisassociateBudgetFromResource_773803, base: "/",
    url: url_DisassociateBudgetFromResource_773804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePrincipalFromPortfolio_773817 = ref object of OpenApiRestCall_772597
proc url_DisassociatePrincipalFromPortfolio_773819(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociatePrincipalFromPortfolio_773818(path: JsonNode;
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
  var valid_773820 = header.getOrDefault("X-Amz-Date")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Date", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Security-Token")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Security-Token", valid_773821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773822 = header.getOrDefault("X-Amz-Target")
  valid_773822 = validateParameter(valid_773822, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"))
  if valid_773822 != nil:
    section.add "X-Amz-Target", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Content-Sha256", valid_773823
  var valid_773824 = header.getOrDefault("X-Amz-Algorithm")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Algorithm", valid_773824
  var valid_773825 = header.getOrDefault("X-Amz-Signature")
  valid_773825 = validateParameter(valid_773825, JString, required = false,
                                 default = nil)
  if valid_773825 != nil:
    section.add "X-Amz-Signature", valid_773825
  var valid_773826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-SignedHeaders", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-Credential")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Credential", valid_773827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773829: Call_DisassociatePrincipalFromPortfolio_773817;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ## 
  let valid = call_773829.validator(path, query, header, formData, body)
  let scheme = call_773829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773829.url(scheme.get, call_773829.host, call_773829.base,
                         call_773829.route, valid.getOrDefault("path"))
  result = hook(call_773829, url, valid)

proc call*(call_773830: Call_DisassociatePrincipalFromPortfolio_773817;
          body: JsonNode): Recallable =
  ## disassociatePrincipalFromPortfolio
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ##   body: JObject (required)
  var body_773831 = newJObject()
  if body != nil:
    body_773831 = body
  result = call_773830.call(nil, nil, nil, nil, body_773831)

var disassociatePrincipalFromPortfolio* = Call_DisassociatePrincipalFromPortfolio_773817(
    name: "disassociatePrincipalFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio",
    validator: validate_DisassociatePrincipalFromPortfolio_773818, base: "/",
    url: url_DisassociatePrincipalFromPortfolio_773819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateProductFromPortfolio_773832 = ref object of OpenApiRestCall_772597
proc url_DisassociateProductFromPortfolio_773834(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateProductFromPortfolio_773833(path: JsonNode;
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
  var valid_773835 = header.getOrDefault("X-Amz-Date")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Date", valid_773835
  var valid_773836 = header.getOrDefault("X-Amz-Security-Token")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Security-Token", valid_773836
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773837 = header.getOrDefault("X-Amz-Target")
  valid_773837 = validateParameter(valid_773837, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateProductFromPortfolio"))
  if valid_773837 != nil:
    section.add "X-Amz-Target", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-Content-Sha256", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Algorithm")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Algorithm", valid_773839
  var valid_773840 = header.getOrDefault("X-Amz-Signature")
  valid_773840 = validateParameter(valid_773840, JString, required = false,
                                 default = nil)
  if valid_773840 != nil:
    section.add "X-Amz-Signature", valid_773840
  var valid_773841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "X-Amz-SignedHeaders", valid_773841
  var valid_773842 = header.getOrDefault("X-Amz-Credential")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-Credential", valid_773842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773844: Call_DisassociateProductFromPortfolio_773832;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified product from the specified portfolio. 
  ## 
  let valid = call_773844.validator(path, query, header, formData, body)
  let scheme = call_773844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773844.url(scheme.get, call_773844.host, call_773844.base,
                         call_773844.route, valid.getOrDefault("path"))
  result = hook(call_773844, url, valid)

proc call*(call_773845: Call_DisassociateProductFromPortfolio_773832;
          body: JsonNode): Recallable =
  ## disassociateProductFromPortfolio
  ## Disassociates the specified product from the specified portfolio. 
  ##   body: JObject (required)
  var body_773846 = newJObject()
  if body != nil:
    body_773846 = body
  result = call_773845.call(nil, nil, nil, nil, body_773846)

var disassociateProductFromPortfolio* = Call_DisassociateProductFromPortfolio_773832(
    name: "disassociateProductFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio",
    validator: validate_DisassociateProductFromPortfolio_773833, base: "/",
    url: url_DisassociateProductFromPortfolio_773834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceActionFromProvisioningArtifact_773847 = ref object of OpenApiRestCall_772597
proc url_DisassociateServiceActionFromProvisioningArtifact_773849(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateServiceActionFromProvisioningArtifact_773848(
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
  var valid_773850 = header.getOrDefault("X-Amz-Date")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-Date", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-Security-Token")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Security-Token", valid_773851
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773852 = header.getOrDefault("X-Amz-Target")
  valid_773852 = validateParameter(valid_773852, JString, required = true, default = newJString("AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"))
  if valid_773852 != nil:
    section.add "X-Amz-Target", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Content-Sha256", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Algorithm")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Algorithm", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Signature")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Signature", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-SignedHeaders", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-Credential")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Credential", valid_773857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773859: Call_DisassociateServiceActionFromProvisioningArtifact_773847;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ## 
  let valid = call_773859.validator(path, query, header, formData, body)
  let scheme = call_773859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773859.url(scheme.get, call_773859.host, call_773859.base,
                         call_773859.route, valid.getOrDefault("path"))
  result = hook(call_773859, url, valid)

proc call*(call_773860: Call_DisassociateServiceActionFromProvisioningArtifact_773847;
          body: JsonNode): Recallable =
  ## disassociateServiceActionFromProvisioningArtifact
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_773861 = newJObject()
  if body != nil:
    body_773861 = body
  result = call_773860.call(nil, nil, nil, nil, body_773861)

var disassociateServiceActionFromProvisioningArtifact* = Call_DisassociateServiceActionFromProvisioningArtifact_773847(
    name: "disassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact",
    validator: validate_DisassociateServiceActionFromProvisioningArtifact_773848,
    base: "/", url: url_DisassociateServiceActionFromProvisioningArtifact_773849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTagOptionFromResource_773862 = ref object of OpenApiRestCall_772597
proc url_DisassociateTagOptionFromResource_773864(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateTagOptionFromResource_773863(path: JsonNode;
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
  var valid_773865 = header.getOrDefault("X-Amz-Date")
  valid_773865 = validateParameter(valid_773865, JString, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "X-Amz-Date", valid_773865
  var valid_773866 = header.getOrDefault("X-Amz-Security-Token")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-Security-Token", valid_773866
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773867 = header.getOrDefault("X-Amz-Target")
  valid_773867 = validateParameter(valid_773867, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateTagOptionFromResource"))
  if valid_773867 != nil:
    section.add "X-Amz-Target", valid_773867
  var valid_773868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "X-Amz-Content-Sha256", valid_773868
  var valid_773869 = header.getOrDefault("X-Amz-Algorithm")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Algorithm", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Signature")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Signature", valid_773870
  var valid_773871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "X-Amz-SignedHeaders", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-Credential")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Credential", valid_773872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773874: Call_DisassociateTagOptionFromResource_773862;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified TagOption from the specified resource.
  ## 
  let valid = call_773874.validator(path, query, header, formData, body)
  let scheme = call_773874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773874.url(scheme.get, call_773874.host, call_773874.base,
                         call_773874.route, valid.getOrDefault("path"))
  result = hook(call_773874, url, valid)

proc call*(call_773875: Call_DisassociateTagOptionFromResource_773862;
          body: JsonNode): Recallable =
  ## disassociateTagOptionFromResource
  ## Disassociates the specified TagOption from the specified resource.
  ##   body: JObject (required)
  var body_773876 = newJObject()
  if body != nil:
    body_773876 = body
  result = call_773875.call(nil, nil, nil, nil, body_773876)

var disassociateTagOptionFromResource* = Call_DisassociateTagOptionFromResource_773862(
    name: "disassociateTagOptionFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource",
    validator: validate_DisassociateTagOptionFromResource_773863, base: "/",
    url: url_DisassociateTagOptionFromResource_773864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSOrganizationsAccess_773877 = ref object of OpenApiRestCall_772597
proc url_EnableAWSOrganizationsAccess_773879(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableAWSOrganizationsAccess_773878(path: JsonNode; query: JsonNode;
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
  var valid_773880 = header.getOrDefault("X-Amz-Date")
  valid_773880 = validateParameter(valid_773880, JString, required = false,
                                 default = nil)
  if valid_773880 != nil:
    section.add "X-Amz-Date", valid_773880
  var valid_773881 = header.getOrDefault("X-Amz-Security-Token")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Security-Token", valid_773881
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773882 = header.getOrDefault("X-Amz-Target")
  valid_773882 = validateParameter(valid_773882, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"))
  if valid_773882 != nil:
    section.add "X-Amz-Target", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-Content-Sha256", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-Algorithm")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-Algorithm", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-Signature")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Signature", valid_773885
  var valid_773886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-SignedHeaders", valid_773886
  var valid_773887 = header.getOrDefault("X-Amz-Credential")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Credential", valid_773887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773889: Call_EnableAWSOrganizationsAccess_773877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ## 
  let valid = call_773889.validator(path, query, header, formData, body)
  let scheme = call_773889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773889.url(scheme.get, call_773889.host, call_773889.base,
                         call_773889.route, valid.getOrDefault("path"))
  result = hook(call_773889, url, valid)

proc call*(call_773890: Call_EnableAWSOrganizationsAccess_773877; body: JsonNode): Recallable =
  ## enableAWSOrganizationsAccess
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ##   body: JObject (required)
  var body_773891 = newJObject()
  if body != nil:
    body_773891 = body
  result = call_773890.call(nil, nil, nil, nil, body_773891)

var enableAWSOrganizationsAccess* = Call_EnableAWSOrganizationsAccess_773877(
    name: "enableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess",
    validator: validate_EnableAWSOrganizationsAccess_773878, base: "/",
    url: url_EnableAWSOrganizationsAccess_773879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductPlan_773892 = ref object of OpenApiRestCall_772597
proc url_ExecuteProvisionedProductPlan_773894(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ExecuteProvisionedProductPlan_773893(path: JsonNode; query: JsonNode;
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
  var valid_773895 = header.getOrDefault("X-Amz-Date")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Date", valid_773895
  var valid_773896 = header.getOrDefault("X-Amz-Security-Token")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Security-Token", valid_773896
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773897 = header.getOrDefault("X-Amz-Target")
  valid_773897 = validateParameter(valid_773897, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"))
  if valid_773897 != nil:
    section.add "X-Amz-Target", valid_773897
  var valid_773898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773898 = validateParameter(valid_773898, JString, required = false,
                                 default = nil)
  if valid_773898 != nil:
    section.add "X-Amz-Content-Sha256", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-Algorithm")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-Algorithm", valid_773899
  var valid_773900 = header.getOrDefault("X-Amz-Signature")
  valid_773900 = validateParameter(valid_773900, JString, required = false,
                                 default = nil)
  if valid_773900 != nil:
    section.add "X-Amz-Signature", valid_773900
  var valid_773901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773901 = validateParameter(valid_773901, JString, required = false,
                                 default = nil)
  if valid_773901 != nil:
    section.add "X-Amz-SignedHeaders", valid_773901
  var valid_773902 = header.getOrDefault("X-Amz-Credential")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-Credential", valid_773902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773904: Call_ExecuteProvisionedProductPlan_773892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ## 
  let valid = call_773904.validator(path, query, header, formData, body)
  let scheme = call_773904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773904.url(scheme.get, call_773904.host, call_773904.base,
                         call_773904.route, valid.getOrDefault("path"))
  result = hook(call_773904, url, valid)

proc call*(call_773905: Call_ExecuteProvisionedProductPlan_773892; body: JsonNode): Recallable =
  ## executeProvisionedProductPlan
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_773906 = newJObject()
  if body != nil:
    body_773906 = body
  result = call_773905.call(nil, nil, nil, nil, body_773906)

var executeProvisionedProductPlan* = Call_ExecuteProvisionedProductPlan_773892(
    name: "executeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan",
    validator: validate_ExecuteProvisionedProductPlan_773893, base: "/",
    url: url_ExecuteProvisionedProductPlan_773894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductServiceAction_773907 = ref object of OpenApiRestCall_772597
proc url_ExecuteProvisionedProductServiceAction_773909(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ExecuteProvisionedProductServiceAction_773908(path: JsonNode;
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
  var valid_773910 = header.getOrDefault("X-Amz-Date")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Date", valid_773910
  var valid_773911 = header.getOrDefault("X-Amz-Security-Token")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Security-Token", valid_773911
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773912 = header.getOrDefault("X-Amz-Target")
  valid_773912 = validateParameter(valid_773912, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"))
  if valid_773912 != nil:
    section.add "X-Amz-Target", valid_773912
  var valid_773913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "X-Amz-Content-Sha256", valid_773913
  var valid_773914 = header.getOrDefault("X-Amz-Algorithm")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "X-Amz-Algorithm", valid_773914
  var valid_773915 = header.getOrDefault("X-Amz-Signature")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-Signature", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-SignedHeaders", valid_773916
  var valid_773917 = header.getOrDefault("X-Amz-Credential")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-Credential", valid_773917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773919: Call_ExecuteProvisionedProductServiceAction_773907;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Executes a self-service action against a provisioned product.
  ## 
  let valid = call_773919.validator(path, query, header, formData, body)
  let scheme = call_773919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773919.url(scheme.get, call_773919.host, call_773919.base,
                         call_773919.route, valid.getOrDefault("path"))
  result = hook(call_773919, url, valid)

proc call*(call_773920: Call_ExecuteProvisionedProductServiceAction_773907;
          body: JsonNode): Recallable =
  ## executeProvisionedProductServiceAction
  ## Executes a self-service action against a provisioned product.
  ##   body: JObject (required)
  var body_773921 = newJObject()
  if body != nil:
    body_773921 = body
  result = call_773920.call(nil, nil, nil, nil, body_773921)

var executeProvisionedProductServiceAction* = Call_ExecuteProvisionedProductServiceAction_773907(
    name: "executeProvisionedProductServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction",
    validator: validate_ExecuteProvisionedProductServiceAction_773908, base: "/",
    url: url_ExecuteProvisionedProductServiceAction_773909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSOrganizationsAccessStatus_773922 = ref object of OpenApiRestCall_772597
proc url_GetAWSOrganizationsAccessStatus_773924(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAWSOrganizationsAccessStatus_773923(path: JsonNode;
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
  var valid_773925 = header.getOrDefault("X-Amz-Date")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-Date", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-Security-Token")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Security-Token", valid_773926
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773927 = header.getOrDefault("X-Amz-Target")
  valid_773927 = validateParameter(valid_773927, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"))
  if valid_773927 != nil:
    section.add "X-Amz-Target", valid_773927
  var valid_773928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "X-Amz-Content-Sha256", valid_773928
  var valid_773929 = header.getOrDefault("X-Amz-Algorithm")
  valid_773929 = validateParameter(valid_773929, JString, required = false,
                                 default = nil)
  if valid_773929 != nil:
    section.add "X-Amz-Algorithm", valid_773929
  var valid_773930 = header.getOrDefault("X-Amz-Signature")
  valid_773930 = validateParameter(valid_773930, JString, required = false,
                                 default = nil)
  if valid_773930 != nil:
    section.add "X-Amz-Signature", valid_773930
  var valid_773931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773931 = validateParameter(valid_773931, JString, required = false,
                                 default = nil)
  if valid_773931 != nil:
    section.add "X-Amz-SignedHeaders", valid_773931
  var valid_773932 = header.getOrDefault("X-Amz-Credential")
  valid_773932 = validateParameter(valid_773932, JString, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "X-Amz-Credential", valid_773932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773934: Call_GetAWSOrganizationsAccessStatus_773922;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ## 
  let valid = call_773934.validator(path, query, header, formData, body)
  let scheme = call_773934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773934.url(scheme.get, call_773934.host, call_773934.base,
                         call_773934.route, valid.getOrDefault("path"))
  result = hook(call_773934, url, valid)

proc call*(call_773935: Call_GetAWSOrganizationsAccessStatus_773922; body: JsonNode): Recallable =
  ## getAWSOrganizationsAccessStatus
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_773936 = newJObject()
  if body != nil:
    body_773936 = body
  result = call_773935.call(nil, nil, nil, nil, body_773936)

var getAWSOrganizationsAccessStatus* = Call_GetAWSOrganizationsAccessStatus_773922(
    name: "getAWSOrganizationsAccessStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus",
    validator: validate_GetAWSOrganizationsAccessStatus_773923, base: "/",
    url: url_GetAWSOrganizationsAccessStatus_773924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAcceptedPortfolioShares_773937 = ref object of OpenApiRestCall_772597
proc url_ListAcceptedPortfolioShares_773939(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAcceptedPortfolioShares_773938(path: JsonNode; query: JsonNode;
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
  var valid_773940 = query.getOrDefault("PageSize")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "PageSize", valid_773940
  var valid_773941 = query.getOrDefault("PageToken")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "PageToken", valid_773941
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773942 = header.getOrDefault("X-Amz-Date")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Date", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-Security-Token")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-Security-Token", valid_773943
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773944 = header.getOrDefault("X-Amz-Target")
  valid_773944 = validateParameter(valid_773944, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListAcceptedPortfolioShares"))
  if valid_773944 != nil:
    section.add "X-Amz-Target", valid_773944
  var valid_773945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773945 = validateParameter(valid_773945, JString, required = false,
                                 default = nil)
  if valid_773945 != nil:
    section.add "X-Amz-Content-Sha256", valid_773945
  var valid_773946 = header.getOrDefault("X-Amz-Algorithm")
  valid_773946 = validateParameter(valid_773946, JString, required = false,
                                 default = nil)
  if valid_773946 != nil:
    section.add "X-Amz-Algorithm", valid_773946
  var valid_773947 = header.getOrDefault("X-Amz-Signature")
  valid_773947 = validateParameter(valid_773947, JString, required = false,
                                 default = nil)
  if valid_773947 != nil:
    section.add "X-Amz-Signature", valid_773947
  var valid_773948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773948 = validateParameter(valid_773948, JString, required = false,
                                 default = nil)
  if valid_773948 != nil:
    section.add "X-Amz-SignedHeaders", valid_773948
  var valid_773949 = header.getOrDefault("X-Amz-Credential")
  valid_773949 = validateParameter(valid_773949, JString, required = false,
                                 default = nil)
  if valid_773949 != nil:
    section.add "X-Amz-Credential", valid_773949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773951: Call_ListAcceptedPortfolioShares_773937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  let valid = call_773951.validator(path, query, header, formData, body)
  let scheme = call_773951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773951.url(scheme.get, call_773951.host, call_773951.base,
                         call_773951.route, valid.getOrDefault("path"))
  result = hook(call_773951, url, valid)

proc call*(call_773952: Call_ListAcceptedPortfolioShares_773937; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listAcceptedPortfolioShares
  ## Lists all portfolios for which sharing was accepted by this account.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773953 = newJObject()
  var body_773954 = newJObject()
  add(query_773953, "PageSize", newJString(PageSize))
  add(query_773953, "PageToken", newJString(PageToken))
  if body != nil:
    body_773954 = body
  result = call_773952.call(nil, query_773953, nil, nil, body_773954)

var listAcceptedPortfolioShares* = Call_ListAcceptedPortfolioShares_773937(
    name: "listAcceptedPortfolioShares", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares",
    validator: validate_ListAcceptedPortfolioShares_773938, base: "/",
    url: url_ListAcceptedPortfolioShares_773939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBudgetsForResource_773956 = ref object of OpenApiRestCall_772597
proc url_ListBudgetsForResource_773958(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBudgetsForResource_773957(path: JsonNode; query: JsonNode;
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
  var valid_773959 = query.getOrDefault("PageSize")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "PageSize", valid_773959
  var valid_773960 = query.getOrDefault("PageToken")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "PageToken", valid_773960
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773961 = header.getOrDefault("X-Amz-Date")
  valid_773961 = validateParameter(valid_773961, JString, required = false,
                                 default = nil)
  if valid_773961 != nil:
    section.add "X-Amz-Date", valid_773961
  var valid_773962 = header.getOrDefault("X-Amz-Security-Token")
  valid_773962 = validateParameter(valid_773962, JString, required = false,
                                 default = nil)
  if valid_773962 != nil:
    section.add "X-Amz-Security-Token", valid_773962
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773963 = header.getOrDefault("X-Amz-Target")
  valid_773963 = validateParameter(valid_773963, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListBudgetsForResource"))
  if valid_773963 != nil:
    section.add "X-Amz-Target", valid_773963
  var valid_773964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773964 = validateParameter(valid_773964, JString, required = false,
                                 default = nil)
  if valid_773964 != nil:
    section.add "X-Amz-Content-Sha256", valid_773964
  var valid_773965 = header.getOrDefault("X-Amz-Algorithm")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-Algorithm", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Signature")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Signature", valid_773966
  var valid_773967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773967 = validateParameter(valid_773967, JString, required = false,
                                 default = nil)
  if valid_773967 != nil:
    section.add "X-Amz-SignedHeaders", valid_773967
  var valid_773968 = header.getOrDefault("X-Amz-Credential")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-Credential", valid_773968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773970: Call_ListBudgetsForResource_773956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the budgets associated to the specified resource.
  ## 
  let valid = call_773970.validator(path, query, header, formData, body)
  let scheme = call_773970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773970.url(scheme.get, call_773970.host, call_773970.base,
                         call_773970.route, valid.getOrDefault("path"))
  result = hook(call_773970, url, valid)

proc call*(call_773971: Call_ListBudgetsForResource_773956; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listBudgetsForResource
  ## Lists all the budgets associated to the specified resource.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773972 = newJObject()
  var body_773973 = newJObject()
  add(query_773972, "PageSize", newJString(PageSize))
  add(query_773972, "PageToken", newJString(PageToken))
  if body != nil:
    body_773973 = body
  result = call_773971.call(nil, query_773972, nil, nil, body_773973)

var listBudgetsForResource* = Call_ListBudgetsForResource_773956(
    name: "listBudgetsForResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource",
    validator: validate_ListBudgetsForResource_773957, base: "/",
    url: url_ListBudgetsForResource_773958, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConstraintsForPortfolio_773974 = ref object of OpenApiRestCall_772597
proc url_ListConstraintsForPortfolio_773976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListConstraintsForPortfolio_773975(path: JsonNode; query: JsonNode;
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
  var valid_773977 = query.getOrDefault("PageSize")
  valid_773977 = validateParameter(valid_773977, JString, required = false,
                                 default = nil)
  if valid_773977 != nil:
    section.add "PageSize", valid_773977
  var valid_773978 = query.getOrDefault("PageToken")
  valid_773978 = validateParameter(valid_773978, JString, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "PageToken", valid_773978
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773979 = header.getOrDefault("X-Amz-Date")
  valid_773979 = validateParameter(valid_773979, JString, required = false,
                                 default = nil)
  if valid_773979 != nil:
    section.add "X-Amz-Date", valid_773979
  var valid_773980 = header.getOrDefault("X-Amz-Security-Token")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "X-Amz-Security-Token", valid_773980
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773981 = header.getOrDefault("X-Amz-Target")
  valid_773981 = validateParameter(valid_773981, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListConstraintsForPortfolio"))
  if valid_773981 != nil:
    section.add "X-Amz-Target", valid_773981
  var valid_773982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773982 = validateParameter(valid_773982, JString, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "X-Amz-Content-Sha256", valid_773982
  var valid_773983 = header.getOrDefault("X-Amz-Algorithm")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "X-Amz-Algorithm", valid_773983
  var valid_773984 = header.getOrDefault("X-Amz-Signature")
  valid_773984 = validateParameter(valid_773984, JString, required = false,
                                 default = nil)
  if valid_773984 != nil:
    section.add "X-Amz-Signature", valid_773984
  var valid_773985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "X-Amz-SignedHeaders", valid_773985
  var valid_773986 = header.getOrDefault("X-Amz-Credential")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-Credential", valid_773986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773988: Call_ListConstraintsForPortfolio_773974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  let valid = call_773988.validator(path, query, header, formData, body)
  let scheme = call_773988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773988.url(scheme.get, call_773988.host, call_773988.base,
                         call_773988.route, valid.getOrDefault("path"))
  result = hook(call_773988, url, valid)

proc call*(call_773989: Call_ListConstraintsForPortfolio_773974; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listConstraintsForPortfolio
  ## Lists the constraints for the specified portfolio and product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773990 = newJObject()
  var body_773991 = newJObject()
  add(query_773990, "PageSize", newJString(PageSize))
  add(query_773990, "PageToken", newJString(PageToken))
  if body != nil:
    body_773991 = body
  result = call_773989.call(nil, query_773990, nil, nil, body_773991)

var listConstraintsForPortfolio* = Call_ListConstraintsForPortfolio_773974(
    name: "listConstraintsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio",
    validator: validate_ListConstraintsForPortfolio_773975, base: "/",
    url: url_ListConstraintsForPortfolio_773976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLaunchPaths_773992 = ref object of OpenApiRestCall_772597
proc url_ListLaunchPaths_773994(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListLaunchPaths_773993(path: JsonNode; query: JsonNode;
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
  var valid_773995 = query.getOrDefault("PageSize")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "PageSize", valid_773995
  var valid_773996 = query.getOrDefault("PageToken")
  valid_773996 = validateParameter(valid_773996, JString, required = false,
                                 default = nil)
  if valid_773996 != nil:
    section.add "PageToken", valid_773996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773997 = header.getOrDefault("X-Amz-Date")
  valid_773997 = validateParameter(valid_773997, JString, required = false,
                                 default = nil)
  if valid_773997 != nil:
    section.add "X-Amz-Date", valid_773997
  var valid_773998 = header.getOrDefault("X-Amz-Security-Token")
  valid_773998 = validateParameter(valid_773998, JString, required = false,
                                 default = nil)
  if valid_773998 != nil:
    section.add "X-Amz-Security-Token", valid_773998
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773999 = header.getOrDefault("X-Amz-Target")
  valid_773999 = validateParameter(valid_773999, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListLaunchPaths"))
  if valid_773999 != nil:
    section.add "X-Amz-Target", valid_773999
  var valid_774000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774000 = validateParameter(valid_774000, JString, required = false,
                                 default = nil)
  if valid_774000 != nil:
    section.add "X-Amz-Content-Sha256", valid_774000
  var valid_774001 = header.getOrDefault("X-Amz-Algorithm")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Algorithm", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-Signature")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Signature", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-SignedHeaders", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Credential")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Credential", valid_774004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774006: Call_ListLaunchPaths_773992; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  let valid = call_774006.validator(path, query, header, formData, body)
  let scheme = call_774006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774006.url(scheme.get, call_774006.host, call_774006.base,
                         call_774006.route, valid.getOrDefault("path"))
  result = hook(call_774006, url, valid)

proc call*(call_774007: Call_ListLaunchPaths_773992; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listLaunchPaths
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774008 = newJObject()
  var body_774009 = newJObject()
  add(query_774008, "PageSize", newJString(PageSize))
  add(query_774008, "PageToken", newJString(PageToken))
  if body != nil:
    body_774009 = body
  result = call_774007.call(nil, query_774008, nil, nil, body_774009)

var listLaunchPaths* = Call_ListLaunchPaths_773992(name: "listLaunchPaths",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths",
    validator: validate_ListLaunchPaths_773993, base: "/", url: url_ListLaunchPaths_773994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationPortfolioAccess_774010 = ref object of OpenApiRestCall_772597
proc url_ListOrganizationPortfolioAccess_774012(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOrganizationPortfolioAccess_774011(path: JsonNode;
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
  var valid_774013 = query.getOrDefault("PageSize")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "PageSize", valid_774013
  var valid_774014 = query.getOrDefault("PageToken")
  valid_774014 = validateParameter(valid_774014, JString, required = false,
                                 default = nil)
  if valid_774014 != nil:
    section.add "PageToken", valid_774014
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774015 = header.getOrDefault("X-Amz-Date")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "X-Amz-Date", valid_774015
  var valid_774016 = header.getOrDefault("X-Amz-Security-Token")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "X-Amz-Security-Token", valid_774016
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774017 = header.getOrDefault("X-Amz-Target")
  valid_774017 = validateParameter(valid_774017, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"))
  if valid_774017 != nil:
    section.add "X-Amz-Target", valid_774017
  var valid_774018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774018 = validateParameter(valid_774018, JString, required = false,
                                 default = nil)
  if valid_774018 != nil:
    section.add "X-Amz-Content-Sha256", valid_774018
  var valid_774019 = header.getOrDefault("X-Amz-Algorithm")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "X-Amz-Algorithm", valid_774019
  var valid_774020 = header.getOrDefault("X-Amz-Signature")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "X-Amz-Signature", valid_774020
  var valid_774021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774021 = validateParameter(valid_774021, JString, required = false,
                                 default = nil)
  if valid_774021 != nil:
    section.add "X-Amz-SignedHeaders", valid_774021
  var valid_774022 = header.getOrDefault("X-Amz-Credential")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "X-Amz-Credential", valid_774022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774024: Call_ListOrganizationPortfolioAccess_774010;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  let valid = call_774024.validator(path, query, header, formData, body)
  let scheme = call_774024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774024.url(scheme.get, call_774024.host, call_774024.base,
                         call_774024.route, valid.getOrDefault("path"))
  result = hook(call_774024, url, valid)

proc call*(call_774025: Call_ListOrganizationPortfolioAccess_774010;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listOrganizationPortfolioAccess
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774026 = newJObject()
  var body_774027 = newJObject()
  add(query_774026, "PageSize", newJString(PageSize))
  add(query_774026, "PageToken", newJString(PageToken))
  if body != nil:
    body_774027 = body
  result = call_774025.call(nil, query_774026, nil, nil, body_774027)

var listOrganizationPortfolioAccess* = Call_ListOrganizationPortfolioAccess_774010(
    name: "listOrganizationPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess",
    validator: validate_ListOrganizationPortfolioAccess_774011, base: "/",
    url: url_ListOrganizationPortfolioAccess_774012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolioAccess_774028 = ref object of OpenApiRestCall_772597
proc url_ListPortfolioAccess_774030(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPortfolioAccess_774029(path: JsonNode; query: JsonNode;
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
  var valid_774031 = header.getOrDefault("X-Amz-Date")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-Date", valid_774031
  var valid_774032 = header.getOrDefault("X-Amz-Security-Token")
  valid_774032 = validateParameter(valid_774032, JString, required = false,
                                 default = nil)
  if valid_774032 != nil:
    section.add "X-Amz-Security-Token", valid_774032
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774033 = header.getOrDefault("X-Amz-Target")
  valid_774033 = validateParameter(valid_774033, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolioAccess"))
  if valid_774033 != nil:
    section.add "X-Amz-Target", valid_774033
  var valid_774034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774034 = validateParameter(valid_774034, JString, required = false,
                                 default = nil)
  if valid_774034 != nil:
    section.add "X-Amz-Content-Sha256", valid_774034
  var valid_774035 = header.getOrDefault("X-Amz-Algorithm")
  valid_774035 = validateParameter(valid_774035, JString, required = false,
                                 default = nil)
  if valid_774035 != nil:
    section.add "X-Amz-Algorithm", valid_774035
  var valid_774036 = header.getOrDefault("X-Amz-Signature")
  valid_774036 = validateParameter(valid_774036, JString, required = false,
                                 default = nil)
  if valid_774036 != nil:
    section.add "X-Amz-Signature", valid_774036
  var valid_774037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774037 = validateParameter(valid_774037, JString, required = false,
                                 default = nil)
  if valid_774037 != nil:
    section.add "X-Amz-SignedHeaders", valid_774037
  var valid_774038 = header.getOrDefault("X-Amz-Credential")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "X-Amz-Credential", valid_774038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774040: Call_ListPortfolioAccess_774028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account IDs that have access to the specified portfolio.
  ## 
  let valid = call_774040.validator(path, query, header, formData, body)
  let scheme = call_774040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774040.url(scheme.get, call_774040.host, call_774040.base,
                         call_774040.route, valid.getOrDefault("path"))
  result = hook(call_774040, url, valid)

proc call*(call_774041: Call_ListPortfolioAccess_774028; body: JsonNode): Recallable =
  ## listPortfolioAccess
  ## Lists the account IDs that have access to the specified portfolio.
  ##   body: JObject (required)
  var body_774042 = newJObject()
  if body != nil:
    body_774042 = body
  result = call_774041.call(nil, nil, nil, nil, body_774042)

var listPortfolioAccess* = Call_ListPortfolioAccess_774028(
    name: "listPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess",
    validator: validate_ListPortfolioAccess_774029, base: "/",
    url: url_ListPortfolioAccess_774030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolios_774043 = ref object of OpenApiRestCall_772597
proc url_ListPortfolios_774045(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPortfolios_774044(path: JsonNode; query: JsonNode;
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
  var valid_774046 = query.getOrDefault("PageSize")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "PageSize", valid_774046
  var valid_774047 = query.getOrDefault("PageToken")
  valid_774047 = validateParameter(valid_774047, JString, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "PageToken", valid_774047
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774048 = header.getOrDefault("X-Amz-Date")
  valid_774048 = validateParameter(valid_774048, JString, required = false,
                                 default = nil)
  if valid_774048 != nil:
    section.add "X-Amz-Date", valid_774048
  var valid_774049 = header.getOrDefault("X-Amz-Security-Token")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "X-Amz-Security-Token", valid_774049
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774050 = header.getOrDefault("X-Amz-Target")
  valid_774050 = validateParameter(valid_774050, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolios"))
  if valid_774050 != nil:
    section.add "X-Amz-Target", valid_774050
  var valid_774051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "X-Amz-Content-Sha256", valid_774051
  var valid_774052 = header.getOrDefault("X-Amz-Algorithm")
  valid_774052 = validateParameter(valid_774052, JString, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "X-Amz-Algorithm", valid_774052
  var valid_774053 = header.getOrDefault("X-Amz-Signature")
  valid_774053 = validateParameter(valid_774053, JString, required = false,
                                 default = nil)
  if valid_774053 != nil:
    section.add "X-Amz-Signature", valid_774053
  var valid_774054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774054 = validateParameter(valid_774054, JString, required = false,
                                 default = nil)
  if valid_774054 != nil:
    section.add "X-Amz-SignedHeaders", valid_774054
  var valid_774055 = header.getOrDefault("X-Amz-Credential")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-Credential", valid_774055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774057: Call_ListPortfolios_774043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios in the catalog.
  ## 
  let valid = call_774057.validator(path, query, header, formData, body)
  let scheme = call_774057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774057.url(scheme.get, call_774057.host, call_774057.base,
                         call_774057.route, valid.getOrDefault("path"))
  result = hook(call_774057, url, valid)

proc call*(call_774058: Call_ListPortfolios_774043; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfolios
  ## Lists all portfolios in the catalog.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774059 = newJObject()
  var body_774060 = newJObject()
  add(query_774059, "PageSize", newJString(PageSize))
  add(query_774059, "PageToken", newJString(PageToken))
  if body != nil:
    body_774060 = body
  result = call_774058.call(nil, query_774059, nil, nil, body_774060)

var listPortfolios* = Call_ListPortfolios_774043(name: "listPortfolios",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios",
    validator: validate_ListPortfolios_774044, base: "/", url: url_ListPortfolios_774045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfoliosForProduct_774061 = ref object of OpenApiRestCall_772597
proc url_ListPortfoliosForProduct_774063(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPortfoliosForProduct_774062(path: JsonNode; query: JsonNode;
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
  var valid_774064 = query.getOrDefault("PageSize")
  valid_774064 = validateParameter(valid_774064, JString, required = false,
                                 default = nil)
  if valid_774064 != nil:
    section.add "PageSize", valid_774064
  var valid_774065 = query.getOrDefault("PageToken")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "PageToken", valid_774065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774066 = header.getOrDefault("X-Amz-Date")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "X-Amz-Date", valid_774066
  var valid_774067 = header.getOrDefault("X-Amz-Security-Token")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Security-Token", valid_774067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774068 = header.getOrDefault("X-Amz-Target")
  valid_774068 = validateParameter(valid_774068, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfoliosForProduct"))
  if valid_774068 != nil:
    section.add "X-Amz-Target", valid_774068
  var valid_774069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-Content-Sha256", valid_774069
  var valid_774070 = header.getOrDefault("X-Amz-Algorithm")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-Algorithm", valid_774070
  var valid_774071 = header.getOrDefault("X-Amz-Signature")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "X-Amz-Signature", valid_774071
  var valid_774072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774072 = validateParameter(valid_774072, JString, required = false,
                                 default = nil)
  if valid_774072 != nil:
    section.add "X-Amz-SignedHeaders", valid_774072
  var valid_774073 = header.getOrDefault("X-Amz-Credential")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "X-Amz-Credential", valid_774073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774075: Call_ListPortfoliosForProduct_774061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  let valid = call_774075.validator(path, query, header, formData, body)
  let scheme = call_774075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774075.url(scheme.get, call_774075.host, call_774075.base,
                         call_774075.route, valid.getOrDefault("path"))
  result = hook(call_774075, url, valid)

proc call*(call_774076: Call_ListPortfoliosForProduct_774061; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfoliosForProduct
  ## Lists all portfolios that the specified product is associated with.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774077 = newJObject()
  var body_774078 = newJObject()
  add(query_774077, "PageSize", newJString(PageSize))
  add(query_774077, "PageToken", newJString(PageToken))
  if body != nil:
    body_774078 = body
  result = call_774076.call(nil, query_774077, nil, nil, body_774078)

var listPortfoliosForProduct* = Call_ListPortfoliosForProduct_774061(
    name: "listPortfoliosForProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct",
    validator: validate_ListPortfoliosForProduct_774062, base: "/",
    url: url_ListPortfoliosForProduct_774063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipalsForPortfolio_774079 = ref object of OpenApiRestCall_772597
proc url_ListPrincipalsForPortfolio_774081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPrincipalsForPortfolio_774080(path: JsonNode; query: JsonNode;
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
  var valid_774082 = query.getOrDefault("PageSize")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "PageSize", valid_774082
  var valid_774083 = query.getOrDefault("PageToken")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "PageToken", valid_774083
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774084 = header.getOrDefault("X-Amz-Date")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Date", valid_774084
  var valid_774085 = header.getOrDefault("X-Amz-Security-Token")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-Security-Token", valid_774085
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774086 = header.getOrDefault("X-Amz-Target")
  valid_774086 = validateParameter(valid_774086, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPrincipalsForPortfolio"))
  if valid_774086 != nil:
    section.add "X-Amz-Target", valid_774086
  var valid_774087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774087 = validateParameter(valid_774087, JString, required = false,
                                 default = nil)
  if valid_774087 != nil:
    section.add "X-Amz-Content-Sha256", valid_774087
  var valid_774088 = header.getOrDefault("X-Amz-Algorithm")
  valid_774088 = validateParameter(valid_774088, JString, required = false,
                                 default = nil)
  if valid_774088 != nil:
    section.add "X-Amz-Algorithm", valid_774088
  var valid_774089 = header.getOrDefault("X-Amz-Signature")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "X-Amz-Signature", valid_774089
  var valid_774090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774090 = validateParameter(valid_774090, JString, required = false,
                                 default = nil)
  if valid_774090 != nil:
    section.add "X-Amz-SignedHeaders", valid_774090
  var valid_774091 = header.getOrDefault("X-Amz-Credential")
  valid_774091 = validateParameter(valid_774091, JString, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "X-Amz-Credential", valid_774091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774093: Call_ListPrincipalsForPortfolio_774079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  let valid = call_774093.validator(path, query, header, formData, body)
  let scheme = call_774093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774093.url(scheme.get, call_774093.host, call_774093.base,
                         call_774093.route, valid.getOrDefault("path"))
  result = hook(call_774093, url, valid)

proc call*(call_774094: Call_ListPrincipalsForPortfolio_774079; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPrincipalsForPortfolio
  ## Lists all principal ARNs associated with the specified portfolio.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774095 = newJObject()
  var body_774096 = newJObject()
  add(query_774095, "PageSize", newJString(PageSize))
  add(query_774095, "PageToken", newJString(PageToken))
  if body != nil:
    body_774096 = body
  result = call_774094.call(nil, query_774095, nil, nil, body_774096)

var listPrincipalsForPortfolio* = Call_ListPrincipalsForPortfolio_774079(
    name: "listPrincipalsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio",
    validator: validate_ListPrincipalsForPortfolio_774080, base: "/",
    url: url_ListPrincipalsForPortfolio_774081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedProductPlans_774097 = ref object of OpenApiRestCall_772597
proc url_ListProvisionedProductPlans_774099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListProvisionedProductPlans_774098(path: JsonNode; query: JsonNode;
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
  var valid_774100 = header.getOrDefault("X-Amz-Date")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Date", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Security-Token")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Security-Token", valid_774101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774102 = header.getOrDefault("X-Amz-Target")
  valid_774102 = validateParameter(valid_774102, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisionedProductPlans"))
  if valid_774102 != nil:
    section.add "X-Amz-Target", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-Content-Sha256", valid_774103
  var valid_774104 = header.getOrDefault("X-Amz-Algorithm")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "X-Amz-Algorithm", valid_774104
  var valid_774105 = header.getOrDefault("X-Amz-Signature")
  valid_774105 = validateParameter(valid_774105, JString, required = false,
                                 default = nil)
  if valid_774105 != nil:
    section.add "X-Amz-Signature", valid_774105
  var valid_774106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774106 = validateParameter(valid_774106, JString, required = false,
                                 default = nil)
  if valid_774106 != nil:
    section.add "X-Amz-SignedHeaders", valid_774106
  var valid_774107 = header.getOrDefault("X-Amz-Credential")
  valid_774107 = validateParameter(valid_774107, JString, required = false,
                                 default = nil)
  if valid_774107 != nil:
    section.add "X-Amz-Credential", valid_774107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774109: Call_ListProvisionedProductPlans_774097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ## 
  let valid = call_774109.validator(path, query, header, formData, body)
  let scheme = call_774109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774109.url(scheme.get, call_774109.host, call_774109.base,
                         call_774109.route, valid.getOrDefault("path"))
  result = hook(call_774109, url, valid)

proc call*(call_774110: Call_ListProvisionedProductPlans_774097; body: JsonNode): Recallable =
  ## listProvisionedProductPlans
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ##   body: JObject (required)
  var body_774111 = newJObject()
  if body != nil:
    body_774111 = body
  result = call_774110.call(nil, nil, nil, nil, body_774111)

var listProvisionedProductPlans* = Call_ListProvisionedProductPlans_774097(
    name: "listProvisionedProductPlans", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans",
    validator: validate_ListProvisionedProductPlans_774098, base: "/",
    url: url_ListProvisionedProductPlans_774099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifacts_774112 = ref object of OpenApiRestCall_772597
proc url_ListProvisioningArtifacts_774114(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListProvisioningArtifacts_774113(path: JsonNode; query: JsonNode;
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
  var valid_774115 = header.getOrDefault("X-Amz-Date")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Date", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Security-Token")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Security-Token", valid_774116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774117 = header.getOrDefault("X-Amz-Target")
  valid_774117 = validateParameter(valid_774117, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifacts"))
  if valid_774117 != nil:
    section.add "X-Amz-Target", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Content-Sha256", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Algorithm")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Algorithm", valid_774119
  var valid_774120 = header.getOrDefault("X-Amz-Signature")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-Signature", valid_774120
  var valid_774121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-SignedHeaders", valid_774121
  var valid_774122 = header.getOrDefault("X-Amz-Credential")
  valid_774122 = validateParameter(valid_774122, JString, required = false,
                                 default = nil)
  if valid_774122 != nil:
    section.add "X-Amz-Credential", valid_774122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774124: Call_ListProvisioningArtifacts_774112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ## 
  let valid = call_774124.validator(path, query, header, formData, body)
  let scheme = call_774124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774124.url(scheme.get, call_774124.host, call_774124.base,
                         call_774124.route, valid.getOrDefault("path"))
  result = hook(call_774124, url, valid)

proc call*(call_774125: Call_ListProvisioningArtifacts_774112; body: JsonNode): Recallable =
  ## listProvisioningArtifacts
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ##   body: JObject (required)
  var body_774126 = newJObject()
  if body != nil:
    body_774126 = body
  result = call_774125.call(nil, nil, nil, nil, body_774126)

var listProvisioningArtifacts* = Call_ListProvisioningArtifacts_774112(
    name: "listProvisioningArtifacts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts",
    validator: validate_ListProvisioningArtifacts_774113, base: "/",
    url: url_ListProvisioningArtifacts_774114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifactsForServiceAction_774127 = ref object of OpenApiRestCall_772597
proc url_ListProvisioningArtifactsForServiceAction_774129(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListProvisioningArtifactsForServiceAction_774128(path: JsonNode;
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
  var valid_774130 = query.getOrDefault("PageSize")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "PageSize", valid_774130
  var valid_774131 = query.getOrDefault("PageToken")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "PageToken", valid_774131
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774132 = header.getOrDefault("X-Amz-Date")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "X-Amz-Date", valid_774132
  var valid_774133 = header.getOrDefault("X-Amz-Security-Token")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "X-Amz-Security-Token", valid_774133
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774134 = header.getOrDefault("X-Amz-Target")
  valid_774134 = validateParameter(valid_774134, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"))
  if valid_774134 != nil:
    section.add "X-Amz-Target", valid_774134
  var valid_774135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-Content-Sha256", valid_774135
  var valid_774136 = header.getOrDefault("X-Amz-Algorithm")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-Algorithm", valid_774136
  var valid_774137 = header.getOrDefault("X-Amz-Signature")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "X-Amz-Signature", valid_774137
  var valid_774138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774138 = validateParameter(valid_774138, JString, required = false,
                                 default = nil)
  if valid_774138 != nil:
    section.add "X-Amz-SignedHeaders", valid_774138
  var valid_774139 = header.getOrDefault("X-Amz-Credential")
  valid_774139 = validateParameter(valid_774139, JString, required = false,
                                 default = nil)
  if valid_774139 != nil:
    section.add "X-Amz-Credential", valid_774139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774141: Call_ListProvisioningArtifactsForServiceAction_774127;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  let valid = call_774141.validator(path, query, header, formData, body)
  let scheme = call_774141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774141.url(scheme.get, call_774141.host, call_774141.base,
                         call_774141.route, valid.getOrDefault("path"))
  result = hook(call_774141, url, valid)

proc call*(call_774142: Call_ListProvisioningArtifactsForServiceAction_774127;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listProvisioningArtifactsForServiceAction
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774143 = newJObject()
  var body_774144 = newJObject()
  add(query_774143, "PageSize", newJString(PageSize))
  add(query_774143, "PageToken", newJString(PageToken))
  if body != nil:
    body_774144 = body
  result = call_774142.call(nil, query_774143, nil, nil, body_774144)

var listProvisioningArtifactsForServiceAction* = Call_ListProvisioningArtifactsForServiceAction_774127(
    name: "listProvisioningArtifactsForServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction",
    validator: validate_ListProvisioningArtifactsForServiceAction_774128,
    base: "/", url: url_ListProvisioningArtifactsForServiceAction_774129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecordHistory_774145 = ref object of OpenApiRestCall_772597
proc url_ListRecordHistory_774147(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRecordHistory_774146(path: JsonNode; query: JsonNode;
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
  var valid_774148 = header.getOrDefault("X-Amz-Date")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "X-Amz-Date", valid_774148
  var valid_774149 = header.getOrDefault("X-Amz-Security-Token")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-Security-Token", valid_774149
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774150 = header.getOrDefault("X-Amz-Target")
  valid_774150 = validateParameter(valid_774150, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListRecordHistory"))
  if valid_774150 != nil:
    section.add "X-Amz-Target", valid_774150
  var valid_774151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-Content-Sha256", valid_774151
  var valid_774152 = header.getOrDefault("X-Amz-Algorithm")
  valid_774152 = validateParameter(valid_774152, JString, required = false,
                                 default = nil)
  if valid_774152 != nil:
    section.add "X-Amz-Algorithm", valid_774152
  var valid_774153 = header.getOrDefault("X-Amz-Signature")
  valid_774153 = validateParameter(valid_774153, JString, required = false,
                                 default = nil)
  if valid_774153 != nil:
    section.add "X-Amz-Signature", valid_774153
  var valid_774154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774154 = validateParameter(valid_774154, JString, required = false,
                                 default = nil)
  if valid_774154 != nil:
    section.add "X-Amz-SignedHeaders", valid_774154
  var valid_774155 = header.getOrDefault("X-Amz-Credential")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "X-Amz-Credential", valid_774155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774157: Call_ListRecordHistory_774145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified requests or all performed requests.
  ## 
  let valid = call_774157.validator(path, query, header, formData, body)
  let scheme = call_774157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774157.url(scheme.get, call_774157.host, call_774157.base,
                         call_774157.route, valid.getOrDefault("path"))
  result = hook(call_774157, url, valid)

proc call*(call_774158: Call_ListRecordHistory_774145; body: JsonNode): Recallable =
  ## listRecordHistory
  ## Lists the specified requests or all performed requests.
  ##   body: JObject (required)
  var body_774159 = newJObject()
  if body != nil:
    body_774159 = body
  result = call_774158.call(nil, nil, nil, nil, body_774159)

var listRecordHistory* = Call_ListRecordHistory_774145(name: "listRecordHistory",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory",
    validator: validate_ListRecordHistory_774146, base: "/",
    url: url_ListRecordHistory_774147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForTagOption_774160 = ref object of OpenApiRestCall_772597
proc url_ListResourcesForTagOption_774162(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourcesForTagOption_774161(path: JsonNode; query: JsonNode;
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
  var valid_774163 = query.getOrDefault("PageSize")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "PageSize", valid_774163
  var valid_774164 = query.getOrDefault("PageToken")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "PageToken", valid_774164
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774165 = header.getOrDefault("X-Amz-Date")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "X-Amz-Date", valid_774165
  var valid_774166 = header.getOrDefault("X-Amz-Security-Token")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-Security-Token", valid_774166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774167 = header.getOrDefault("X-Amz-Target")
  valid_774167 = validateParameter(valid_774167, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListResourcesForTagOption"))
  if valid_774167 != nil:
    section.add "X-Amz-Target", valid_774167
  var valid_774168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "X-Amz-Content-Sha256", valid_774168
  var valid_774169 = header.getOrDefault("X-Amz-Algorithm")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "X-Amz-Algorithm", valid_774169
  var valid_774170 = header.getOrDefault("X-Amz-Signature")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "X-Amz-Signature", valid_774170
  var valid_774171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774171 = validateParameter(valid_774171, JString, required = false,
                                 default = nil)
  if valid_774171 != nil:
    section.add "X-Amz-SignedHeaders", valid_774171
  var valid_774172 = header.getOrDefault("X-Amz-Credential")
  valid_774172 = validateParameter(valid_774172, JString, required = false,
                                 default = nil)
  if valid_774172 != nil:
    section.add "X-Amz-Credential", valid_774172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774174: Call_ListResourcesForTagOption_774160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources associated with the specified TagOption.
  ## 
  let valid = call_774174.validator(path, query, header, formData, body)
  let scheme = call_774174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774174.url(scheme.get, call_774174.host, call_774174.base,
                         call_774174.route, valid.getOrDefault("path"))
  result = hook(call_774174, url, valid)

proc call*(call_774175: Call_ListResourcesForTagOption_774160; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listResourcesForTagOption
  ## Lists the resources associated with the specified TagOption.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774176 = newJObject()
  var body_774177 = newJObject()
  add(query_774176, "PageSize", newJString(PageSize))
  add(query_774176, "PageToken", newJString(PageToken))
  if body != nil:
    body_774177 = body
  result = call_774175.call(nil, query_774176, nil, nil, body_774177)

var listResourcesForTagOption* = Call_ListResourcesForTagOption_774160(
    name: "listResourcesForTagOption", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption",
    validator: validate_ListResourcesForTagOption_774161, base: "/",
    url: url_ListResourcesForTagOption_774162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActions_774178 = ref object of OpenApiRestCall_772597
proc url_ListServiceActions_774180(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListServiceActions_774179(path: JsonNode; query: JsonNode;
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
  var valid_774181 = query.getOrDefault("PageSize")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "PageSize", valid_774181
  var valid_774182 = query.getOrDefault("PageToken")
  valid_774182 = validateParameter(valid_774182, JString, required = false,
                                 default = nil)
  if valid_774182 != nil:
    section.add "PageToken", valid_774182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774183 = header.getOrDefault("X-Amz-Date")
  valid_774183 = validateParameter(valid_774183, JString, required = false,
                                 default = nil)
  if valid_774183 != nil:
    section.add "X-Amz-Date", valid_774183
  var valid_774184 = header.getOrDefault("X-Amz-Security-Token")
  valid_774184 = validateParameter(valid_774184, JString, required = false,
                                 default = nil)
  if valid_774184 != nil:
    section.add "X-Amz-Security-Token", valid_774184
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774185 = header.getOrDefault("X-Amz-Target")
  valid_774185 = validateParameter(valid_774185, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActions"))
  if valid_774185 != nil:
    section.add "X-Amz-Target", valid_774185
  var valid_774186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "X-Amz-Content-Sha256", valid_774186
  var valid_774187 = header.getOrDefault("X-Amz-Algorithm")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "X-Amz-Algorithm", valid_774187
  var valid_774188 = header.getOrDefault("X-Amz-Signature")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "X-Amz-Signature", valid_774188
  var valid_774189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774189 = validateParameter(valid_774189, JString, required = false,
                                 default = nil)
  if valid_774189 != nil:
    section.add "X-Amz-SignedHeaders", valid_774189
  var valid_774190 = header.getOrDefault("X-Amz-Credential")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "X-Amz-Credential", valid_774190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774192: Call_ListServiceActions_774178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all self-service actions.
  ## 
  let valid = call_774192.validator(path, query, header, formData, body)
  let scheme = call_774192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774192.url(scheme.get, call_774192.host, call_774192.base,
                         call_774192.route, valid.getOrDefault("path"))
  result = hook(call_774192, url, valid)

proc call*(call_774193: Call_ListServiceActions_774178; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActions
  ## Lists all self-service actions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774194 = newJObject()
  var body_774195 = newJObject()
  add(query_774194, "PageSize", newJString(PageSize))
  add(query_774194, "PageToken", newJString(PageToken))
  if body != nil:
    body_774195 = body
  result = call_774193.call(nil, query_774194, nil, nil, body_774195)

var listServiceActions* = Call_ListServiceActions_774178(
    name: "listServiceActions", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions",
    validator: validate_ListServiceActions_774179, base: "/",
    url: url_ListServiceActions_774180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActionsForProvisioningArtifact_774196 = ref object of OpenApiRestCall_772597
proc url_ListServiceActionsForProvisioningArtifact_774198(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListServiceActionsForProvisioningArtifact_774197(path: JsonNode;
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
  var valid_774199 = query.getOrDefault("PageSize")
  valid_774199 = validateParameter(valid_774199, JString, required = false,
                                 default = nil)
  if valid_774199 != nil:
    section.add "PageSize", valid_774199
  var valid_774200 = query.getOrDefault("PageToken")
  valid_774200 = validateParameter(valid_774200, JString, required = false,
                                 default = nil)
  if valid_774200 != nil:
    section.add "PageToken", valid_774200
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774201 = header.getOrDefault("X-Amz-Date")
  valid_774201 = validateParameter(valid_774201, JString, required = false,
                                 default = nil)
  if valid_774201 != nil:
    section.add "X-Amz-Date", valid_774201
  var valid_774202 = header.getOrDefault("X-Amz-Security-Token")
  valid_774202 = validateParameter(valid_774202, JString, required = false,
                                 default = nil)
  if valid_774202 != nil:
    section.add "X-Amz-Security-Token", valid_774202
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774203 = header.getOrDefault("X-Amz-Target")
  valid_774203 = validateParameter(valid_774203, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"))
  if valid_774203 != nil:
    section.add "X-Amz-Target", valid_774203
  var valid_774204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774204 = validateParameter(valid_774204, JString, required = false,
                                 default = nil)
  if valid_774204 != nil:
    section.add "X-Amz-Content-Sha256", valid_774204
  var valid_774205 = header.getOrDefault("X-Amz-Algorithm")
  valid_774205 = validateParameter(valid_774205, JString, required = false,
                                 default = nil)
  if valid_774205 != nil:
    section.add "X-Amz-Algorithm", valid_774205
  var valid_774206 = header.getOrDefault("X-Amz-Signature")
  valid_774206 = validateParameter(valid_774206, JString, required = false,
                                 default = nil)
  if valid_774206 != nil:
    section.add "X-Amz-Signature", valid_774206
  var valid_774207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774207 = validateParameter(valid_774207, JString, required = false,
                                 default = nil)
  if valid_774207 != nil:
    section.add "X-Amz-SignedHeaders", valid_774207
  var valid_774208 = header.getOrDefault("X-Amz-Credential")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "X-Amz-Credential", valid_774208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774210: Call_ListServiceActionsForProvisioningArtifact_774196;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  let valid = call_774210.validator(path, query, header, formData, body)
  let scheme = call_774210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774210.url(scheme.get, call_774210.host, call_774210.base,
                         call_774210.route, valid.getOrDefault("path"))
  result = hook(call_774210, url, valid)

proc call*(call_774211: Call_ListServiceActionsForProvisioningArtifact_774196;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActionsForProvisioningArtifact
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774212 = newJObject()
  var body_774213 = newJObject()
  add(query_774212, "PageSize", newJString(PageSize))
  add(query_774212, "PageToken", newJString(PageToken))
  if body != nil:
    body_774213 = body
  result = call_774211.call(nil, query_774212, nil, nil, body_774213)

var listServiceActionsForProvisioningArtifact* = Call_ListServiceActionsForProvisioningArtifact_774196(
    name: "listServiceActionsForProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact",
    validator: validate_ListServiceActionsForProvisioningArtifact_774197,
    base: "/", url: url_ListServiceActionsForProvisioningArtifact_774198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStackInstancesForProvisionedProduct_774214 = ref object of OpenApiRestCall_772597
proc url_ListStackInstancesForProvisionedProduct_774216(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListStackInstancesForProvisionedProduct_774215(path: JsonNode;
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
  var valid_774217 = header.getOrDefault("X-Amz-Date")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "X-Amz-Date", valid_774217
  var valid_774218 = header.getOrDefault("X-Amz-Security-Token")
  valid_774218 = validateParameter(valid_774218, JString, required = false,
                                 default = nil)
  if valid_774218 != nil:
    section.add "X-Amz-Security-Token", valid_774218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774219 = header.getOrDefault("X-Amz-Target")
  valid_774219 = validateParameter(valid_774219, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"))
  if valid_774219 != nil:
    section.add "X-Amz-Target", valid_774219
  var valid_774220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774220 = validateParameter(valid_774220, JString, required = false,
                                 default = nil)
  if valid_774220 != nil:
    section.add "X-Amz-Content-Sha256", valid_774220
  var valid_774221 = header.getOrDefault("X-Amz-Algorithm")
  valid_774221 = validateParameter(valid_774221, JString, required = false,
                                 default = nil)
  if valid_774221 != nil:
    section.add "X-Amz-Algorithm", valid_774221
  var valid_774222 = header.getOrDefault("X-Amz-Signature")
  valid_774222 = validateParameter(valid_774222, JString, required = false,
                                 default = nil)
  if valid_774222 != nil:
    section.add "X-Amz-Signature", valid_774222
  var valid_774223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774223 = validateParameter(valid_774223, JString, required = false,
                                 default = nil)
  if valid_774223 != nil:
    section.add "X-Amz-SignedHeaders", valid_774223
  var valid_774224 = header.getOrDefault("X-Amz-Credential")
  valid_774224 = validateParameter(valid_774224, JString, required = false,
                                 default = nil)
  if valid_774224 != nil:
    section.add "X-Amz-Credential", valid_774224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774226: Call_ListStackInstancesForProvisionedProduct_774214;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ## 
  let valid = call_774226.validator(path, query, header, formData, body)
  let scheme = call_774226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774226.url(scheme.get, call_774226.host, call_774226.base,
                         call_774226.route, valid.getOrDefault("path"))
  result = hook(call_774226, url, valid)

proc call*(call_774227: Call_ListStackInstancesForProvisionedProduct_774214;
          body: JsonNode): Recallable =
  ## listStackInstancesForProvisionedProduct
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ##   body: JObject (required)
  var body_774228 = newJObject()
  if body != nil:
    body_774228 = body
  result = call_774227.call(nil, nil, nil, nil, body_774228)

var listStackInstancesForProvisionedProduct* = Call_ListStackInstancesForProvisionedProduct_774214(
    name: "listStackInstancesForProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct",
    validator: validate_ListStackInstancesForProvisionedProduct_774215, base: "/",
    url: url_ListStackInstancesForProvisionedProduct_774216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagOptions_774229 = ref object of OpenApiRestCall_772597
proc url_ListTagOptions_774231(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagOptions_774230(path: JsonNode; query: JsonNode;
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
  var valid_774232 = query.getOrDefault("PageSize")
  valid_774232 = validateParameter(valid_774232, JString, required = false,
                                 default = nil)
  if valid_774232 != nil:
    section.add "PageSize", valid_774232
  var valid_774233 = query.getOrDefault("PageToken")
  valid_774233 = validateParameter(valid_774233, JString, required = false,
                                 default = nil)
  if valid_774233 != nil:
    section.add "PageToken", valid_774233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774234 = header.getOrDefault("X-Amz-Date")
  valid_774234 = validateParameter(valid_774234, JString, required = false,
                                 default = nil)
  if valid_774234 != nil:
    section.add "X-Amz-Date", valid_774234
  var valid_774235 = header.getOrDefault("X-Amz-Security-Token")
  valid_774235 = validateParameter(valid_774235, JString, required = false,
                                 default = nil)
  if valid_774235 != nil:
    section.add "X-Amz-Security-Token", valid_774235
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774236 = header.getOrDefault("X-Amz-Target")
  valid_774236 = validateParameter(valid_774236, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListTagOptions"))
  if valid_774236 != nil:
    section.add "X-Amz-Target", valid_774236
  var valid_774237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774237 = validateParameter(valid_774237, JString, required = false,
                                 default = nil)
  if valid_774237 != nil:
    section.add "X-Amz-Content-Sha256", valid_774237
  var valid_774238 = header.getOrDefault("X-Amz-Algorithm")
  valid_774238 = validateParameter(valid_774238, JString, required = false,
                                 default = nil)
  if valid_774238 != nil:
    section.add "X-Amz-Algorithm", valid_774238
  var valid_774239 = header.getOrDefault("X-Amz-Signature")
  valid_774239 = validateParameter(valid_774239, JString, required = false,
                                 default = nil)
  if valid_774239 != nil:
    section.add "X-Amz-Signature", valid_774239
  var valid_774240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774240 = validateParameter(valid_774240, JString, required = false,
                                 default = nil)
  if valid_774240 != nil:
    section.add "X-Amz-SignedHeaders", valid_774240
  var valid_774241 = header.getOrDefault("X-Amz-Credential")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "X-Amz-Credential", valid_774241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774243: Call_ListTagOptions_774229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  let valid = call_774243.validator(path, query, header, formData, body)
  let scheme = call_774243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774243.url(scheme.get, call_774243.host, call_774243.base,
                         call_774243.route, valid.getOrDefault("path"))
  result = hook(call_774243, url, valid)

proc call*(call_774244: Call_ListTagOptions_774229; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listTagOptions
  ## Lists the specified TagOptions or all TagOptions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774245 = newJObject()
  var body_774246 = newJObject()
  add(query_774245, "PageSize", newJString(PageSize))
  add(query_774245, "PageToken", newJString(PageToken))
  if body != nil:
    body_774246 = body
  result = call_774244.call(nil, query_774245, nil, nil, body_774246)

var listTagOptions* = Call_ListTagOptions_774229(name: "listTagOptions",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions",
    validator: validate_ListTagOptions_774230, base: "/", url: url_ListTagOptions_774231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ProvisionProduct_774247 = ref object of OpenApiRestCall_772597
proc url_ProvisionProduct_774249(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ProvisionProduct_774248(path: JsonNode; query: JsonNode;
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
  var valid_774250 = header.getOrDefault("X-Amz-Date")
  valid_774250 = validateParameter(valid_774250, JString, required = false,
                                 default = nil)
  if valid_774250 != nil:
    section.add "X-Amz-Date", valid_774250
  var valid_774251 = header.getOrDefault("X-Amz-Security-Token")
  valid_774251 = validateParameter(valid_774251, JString, required = false,
                                 default = nil)
  if valid_774251 != nil:
    section.add "X-Amz-Security-Token", valid_774251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774252 = header.getOrDefault("X-Amz-Target")
  valid_774252 = validateParameter(valid_774252, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ProvisionProduct"))
  if valid_774252 != nil:
    section.add "X-Amz-Target", valid_774252
  var valid_774253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774253 = validateParameter(valid_774253, JString, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "X-Amz-Content-Sha256", valid_774253
  var valid_774254 = header.getOrDefault("X-Amz-Algorithm")
  valid_774254 = validateParameter(valid_774254, JString, required = false,
                                 default = nil)
  if valid_774254 != nil:
    section.add "X-Amz-Algorithm", valid_774254
  var valid_774255 = header.getOrDefault("X-Amz-Signature")
  valid_774255 = validateParameter(valid_774255, JString, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "X-Amz-Signature", valid_774255
  var valid_774256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774256 = validateParameter(valid_774256, JString, required = false,
                                 default = nil)
  if valid_774256 != nil:
    section.add "X-Amz-SignedHeaders", valid_774256
  var valid_774257 = header.getOrDefault("X-Amz-Credential")
  valid_774257 = validateParameter(valid_774257, JString, required = false,
                                 default = nil)
  if valid_774257 != nil:
    section.add "X-Amz-Credential", valid_774257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774259: Call_ProvisionProduct_774247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ## 
  let valid = call_774259.validator(path, query, header, formData, body)
  let scheme = call_774259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774259.url(scheme.get, call_774259.host, call_774259.base,
                         call_774259.route, valid.getOrDefault("path"))
  result = hook(call_774259, url, valid)

proc call*(call_774260: Call_ProvisionProduct_774247; body: JsonNode): Recallable =
  ## provisionProduct
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ##   body: JObject (required)
  var body_774261 = newJObject()
  if body != nil:
    body_774261 = body
  result = call_774260.call(nil, nil, nil, nil, body_774261)

var provisionProduct* = Call_ProvisionProduct_774247(name: "provisionProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct",
    validator: validate_ProvisionProduct_774248, base: "/",
    url: url_ProvisionProduct_774249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectPortfolioShare_774262 = ref object of OpenApiRestCall_772597
proc url_RejectPortfolioShare_774264(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RejectPortfolioShare_774263(path: JsonNode; query: JsonNode;
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
  var valid_774265 = header.getOrDefault("X-Amz-Date")
  valid_774265 = validateParameter(valid_774265, JString, required = false,
                                 default = nil)
  if valid_774265 != nil:
    section.add "X-Amz-Date", valid_774265
  var valid_774266 = header.getOrDefault("X-Amz-Security-Token")
  valid_774266 = validateParameter(valid_774266, JString, required = false,
                                 default = nil)
  if valid_774266 != nil:
    section.add "X-Amz-Security-Token", valid_774266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774267 = header.getOrDefault("X-Amz-Target")
  valid_774267 = validateParameter(valid_774267, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.RejectPortfolioShare"))
  if valid_774267 != nil:
    section.add "X-Amz-Target", valid_774267
  var valid_774268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774268 = validateParameter(valid_774268, JString, required = false,
                                 default = nil)
  if valid_774268 != nil:
    section.add "X-Amz-Content-Sha256", valid_774268
  var valid_774269 = header.getOrDefault("X-Amz-Algorithm")
  valid_774269 = validateParameter(valid_774269, JString, required = false,
                                 default = nil)
  if valid_774269 != nil:
    section.add "X-Amz-Algorithm", valid_774269
  var valid_774270 = header.getOrDefault("X-Amz-Signature")
  valid_774270 = validateParameter(valid_774270, JString, required = false,
                                 default = nil)
  if valid_774270 != nil:
    section.add "X-Amz-Signature", valid_774270
  var valid_774271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774271 = validateParameter(valid_774271, JString, required = false,
                                 default = nil)
  if valid_774271 != nil:
    section.add "X-Amz-SignedHeaders", valid_774271
  var valid_774272 = header.getOrDefault("X-Amz-Credential")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "X-Amz-Credential", valid_774272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774274: Call_RejectPortfolioShare_774262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an offer to share the specified portfolio.
  ## 
  let valid = call_774274.validator(path, query, header, formData, body)
  let scheme = call_774274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774274.url(scheme.get, call_774274.host, call_774274.base,
                         call_774274.route, valid.getOrDefault("path"))
  result = hook(call_774274, url, valid)

proc call*(call_774275: Call_RejectPortfolioShare_774262; body: JsonNode): Recallable =
  ## rejectPortfolioShare
  ## Rejects an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_774276 = newJObject()
  if body != nil:
    body_774276 = body
  result = call_774275.call(nil, nil, nil, nil, body_774276)

var rejectPortfolioShare* = Call_RejectPortfolioShare_774262(
    name: "rejectPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare",
    validator: validate_RejectPortfolioShare_774263, base: "/",
    url: url_RejectPortfolioShare_774264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScanProvisionedProducts_774277 = ref object of OpenApiRestCall_772597
proc url_ScanProvisionedProducts_774279(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ScanProvisionedProducts_774278(path: JsonNode; query: JsonNode;
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
  var valid_774280 = header.getOrDefault("X-Amz-Date")
  valid_774280 = validateParameter(valid_774280, JString, required = false,
                                 default = nil)
  if valid_774280 != nil:
    section.add "X-Amz-Date", valid_774280
  var valid_774281 = header.getOrDefault("X-Amz-Security-Token")
  valid_774281 = validateParameter(valid_774281, JString, required = false,
                                 default = nil)
  if valid_774281 != nil:
    section.add "X-Amz-Security-Token", valid_774281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774282 = header.getOrDefault("X-Amz-Target")
  valid_774282 = validateParameter(valid_774282, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ScanProvisionedProducts"))
  if valid_774282 != nil:
    section.add "X-Amz-Target", valid_774282
  var valid_774283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774283 = validateParameter(valid_774283, JString, required = false,
                                 default = nil)
  if valid_774283 != nil:
    section.add "X-Amz-Content-Sha256", valid_774283
  var valid_774284 = header.getOrDefault("X-Amz-Algorithm")
  valid_774284 = validateParameter(valid_774284, JString, required = false,
                                 default = nil)
  if valid_774284 != nil:
    section.add "X-Amz-Algorithm", valid_774284
  var valid_774285 = header.getOrDefault("X-Amz-Signature")
  valid_774285 = validateParameter(valid_774285, JString, required = false,
                                 default = nil)
  if valid_774285 != nil:
    section.add "X-Amz-Signature", valid_774285
  var valid_774286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774286 = validateParameter(valid_774286, JString, required = false,
                                 default = nil)
  if valid_774286 != nil:
    section.add "X-Amz-SignedHeaders", valid_774286
  var valid_774287 = header.getOrDefault("X-Amz-Credential")
  valid_774287 = validateParameter(valid_774287, JString, required = false,
                                 default = nil)
  if valid_774287 != nil:
    section.add "X-Amz-Credential", valid_774287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774289: Call_ScanProvisionedProducts_774277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ## 
  let valid = call_774289.validator(path, query, header, formData, body)
  let scheme = call_774289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774289.url(scheme.get, call_774289.host, call_774289.base,
                         call_774289.route, valid.getOrDefault("path"))
  result = hook(call_774289, url, valid)

proc call*(call_774290: Call_ScanProvisionedProducts_774277; body: JsonNode): Recallable =
  ## scanProvisionedProducts
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ##   body: JObject (required)
  var body_774291 = newJObject()
  if body != nil:
    body_774291 = body
  result = call_774290.call(nil, nil, nil, nil, body_774291)

var scanProvisionedProducts* = Call_ScanProvisionedProducts_774277(
    name: "scanProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts",
    validator: validate_ScanProvisionedProducts_774278, base: "/",
    url: url_ScanProvisionedProducts_774279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProducts_774292 = ref object of OpenApiRestCall_772597
proc url_SearchProducts_774294(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchProducts_774293(path: JsonNode; query: JsonNode;
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
  var valid_774295 = query.getOrDefault("PageSize")
  valid_774295 = validateParameter(valid_774295, JString, required = false,
                                 default = nil)
  if valid_774295 != nil:
    section.add "PageSize", valid_774295
  var valid_774296 = query.getOrDefault("PageToken")
  valid_774296 = validateParameter(valid_774296, JString, required = false,
                                 default = nil)
  if valid_774296 != nil:
    section.add "PageToken", valid_774296
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774297 = header.getOrDefault("X-Amz-Date")
  valid_774297 = validateParameter(valid_774297, JString, required = false,
                                 default = nil)
  if valid_774297 != nil:
    section.add "X-Amz-Date", valid_774297
  var valid_774298 = header.getOrDefault("X-Amz-Security-Token")
  valid_774298 = validateParameter(valid_774298, JString, required = false,
                                 default = nil)
  if valid_774298 != nil:
    section.add "X-Amz-Security-Token", valid_774298
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774299 = header.getOrDefault("X-Amz-Target")
  valid_774299 = validateParameter(valid_774299, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProducts"))
  if valid_774299 != nil:
    section.add "X-Amz-Target", valid_774299
  var valid_774300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774300 = validateParameter(valid_774300, JString, required = false,
                                 default = nil)
  if valid_774300 != nil:
    section.add "X-Amz-Content-Sha256", valid_774300
  var valid_774301 = header.getOrDefault("X-Amz-Algorithm")
  valid_774301 = validateParameter(valid_774301, JString, required = false,
                                 default = nil)
  if valid_774301 != nil:
    section.add "X-Amz-Algorithm", valid_774301
  var valid_774302 = header.getOrDefault("X-Amz-Signature")
  valid_774302 = validateParameter(valid_774302, JString, required = false,
                                 default = nil)
  if valid_774302 != nil:
    section.add "X-Amz-Signature", valid_774302
  var valid_774303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "X-Amz-SignedHeaders", valid_774303
  var valid_774304 = header.getOrDefault("X-Amz-Credential")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-Credential", valid_774304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774306: Call_SearchProducts_774292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products to which the caller has access.
  ## 
  let valid = call_774306.validator(path, query, header, formData, body)
  let scheme = call_774306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774306.url(scheme.get, call_774306.host, call_774306.base,
                         call_774306.route, valid.getOrDefault("path"))
  result = hook(call_774306, url, valid)

proc call*(call_774307: Call_SearchProducts_774292; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProducts
  ## Gets information about the products to which the caller has access.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774308 = newJObject()
  var body_774309 = newJObject()
  add(query_774308, "PageSize", newJString(PageSize))
  add(query_774308, "PageToken", newJString(PageToken))
  if body != nil:
    body_774309 = body
  result = call_774307.call(nil, query_774308, nil, nil, body_774309)

var searchProducts* = Call_SearchProducts_774292(name: "searchProducts",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts",
    validator: validate_SearchProducts_774293, base: "/", url: url_SearchProducts_774294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProductsAsAdmin_774310 = ref object of OpenApiRestCall_772597
proc url_SearchProductsAsAdmin_774312(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchProductsAsAdmin_774311(path: JsonNode; query: JsonNode;
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
  var valid_774313 = query.getOrDefault("PageSize")
  valid_774313 = validateParameter(valid_774313, JString, required = false,
                                 default = nil)
  if valid_774313 != nil:
    section.add "PageSize", valid_774313
  var valid_774314 = query.getOrDefault("PageToken")
  valid_774314 = validateParameter(valid_774314, JString, required = false,
                                 default = nil)
  if valid_774314 != nil:
    section.add "PageToken", valid_774314
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774315 = header.getOrDefault("X-Amz-Date")
  valid_774315 = validateParameter(valid_774315, JString, required = false,
                                 default = nil)
  if valid_774315 != nil:
    section.add "X-Amz-Date", valid_774315
  var valid_774316 = header.getOrDefault("X-Amz-Security-Token")
  valid_774316 = validateParameter(valid_774316, JString, required = false,
                                 default = nil)
  if valid_774316 != nil:
    section.add "X-Amz-Security-Token", valid_774316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774317 = header.getOrDefault("X-Amz-Target")
  valid_774317 = validateParameter(valid_774317, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProductsAsAdmin"))
  if valid_774317 != nil:
    section.add "X-Amz-Target", valid_774317
  var valid_774318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774318 = validateParameter(valid_774318, JString, required = false,
                                 default = nil)
  if valid_774318 != nil:
    section.add "X-Amz-Content-Sha256", valid_774318
  var valid_774319 = header.getOrDefault("X-Amz-Algorithm")
  valid_774319 = validateParameter(valid_774319, JString, required = false,
                                 default = nil)
  if valid_774319 != nil:
    section.add "X-Amz-Algorithm", valid_774319
  var valid_774320 = header.getOrDefault("X-Amz-Signature")
  valid_774320 = validateParameter(valid_774320, JString, required = false,
                                 default = nil)
  if valid_774320 != nil:
    section.add "X-Amz-Signature", valid_774320
  var valid_774321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-SignedHeaders", valid_774321
  var valid_774322 = header.getOrDefault("X-Amz-Credential")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Credential", valid_774322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774324: Call_SearchProductsAsAdmin_774310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  let valid = call_774324.validator(path, query, header, formData, body)
  let scheme = call_774324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774324.url(scheme.get, call_774324.host, call_774324.base,
                         call_774324.route, valid.getOrDefault("path"))
  result = hook(call_774324, url, valid)

proc call*(call_774325: Call_SearchProductsAsAdmin_774310; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProductsAsAdmin
  ## Gets information about the products for the specified portfolio or all products.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774326 = newJObject()
  var body_774327 = newJObject()
  add(query_774326, "PageSize", newJString(PageSize))
  add(query_774326, "PageToken", newJString(PageToken))
  if body != nil:
    body_774327 = body
  result = call_774325.call(nil, query_774326, nil, nil, body_774327)

var searchProductsAsAdmin* = Call_SearchProductsAsAdmin_774310(
    name: "searchProductsAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin",
    validator: validate_SearchProductsAsAdmin_774311, base: "/",
    url: url_SearchProductsAsAdmin_774312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProvisionedProducts_774328 = ref object of OpenApiRestCall_772597
proc url_SearchProvisionedProducts_774330(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchProvisionedProducts_774329(path: JsonNode; query: JsonNode;
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
  var valid_774331 = query.getOrDefault("PageSize")
  valid_774331 = validateParameter(valid_774331, JString, required = false,
                                 default = nil)
  if valid_774331 != nil:
    section.add "PageSize", valid_774331
  var valid_774332 = query.getOrDefault("PageToken")
  valid_774332 = validateParameter(valid_774332, JString, required = false,
                                 default = nil)
  if valid_774332 != nil:
    section.add "PageToken", valid_774332
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774333 = header.getOrDefault("X-Amz-Date")
  valid_774333 = validateParameter(valid_774333, JString, required = false,
                                 default = nil)
  if valid_774333 != nil:
    section.add "X-Amz-Date", valid_774333
  var valid_774334 = header.getOrDefault("X-Amz-Security-Token")
  valid_774334 = validateParameter(valid_774334, JString, required = false,
                                 default = nil)
  if valid_774334 != nil:
    section.add "X-Amz-Security-Token", valid_774334
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774335 = header.getOrDefault("X-Amz-Target")
  valid_774335 = validateParameter(valid_774335, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProvisionedProducts"))
  if valid_774335 != nil:
    section.add "X-Amz-Target", valid_774335
  var valid_774336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774336 = validateParameter(valid_774336, JString, required = false,
                                 default = nil)
  if valid_774336 != nil:
    section.add "X-Amz-Content-Sha256", valid_774336
  var valid_774337 = header.getOrDefault("X-Amz-Algorithm")
  valid_774337 = validateParameter(valid_774337, JString, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "X-Amz-Algorithm", valid_774337
  var valid_774338 = header.getOrDefault("X-Amz-Signature")
  valid_774338 = validateParameter(valid_774338, JString, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "X-Amz-Signature", valid_774338
  var valid_774339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774339 = validateParameter(valid_774339, JString, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "X-Amz-SignedHeaders", valid_774339
  var valid_774340 = header.getOrDefault("X-Amz-Credential")
  valid_774340 = validateParameter(valid_774340, JString, required = false,
                                 default = nil)
  if valid_774340 != nil:
    section.add "X-Amz-Credential", valid_774340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774342: Call_SearchProvisionedProducts_774328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  let valid = call_774342.validator(path, query, header, formData, body)
  let scheme = call_774342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774342.url(scheme.get, call_774342.host, call_774342.base,
                         call_774342.route, valid.getOrDefault("path"))
  result = hook(call_774342, url, valid)

proc call*(call_774343: Call_SearchProvisionedProducts_774328; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProvisionedProducts
  ## Gets information about the provisioned products that meet the specified criteria.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774344 = newJObject()
  var body_774345 = newJObject()
  add(query_774344, "PageSize", newJString(PageSize))
  add(query_774344, "PageToken", newJString(PageToken))
  if body != nil:
    body_774345 = body
  result = call_774343.call(nil, query_774344, nil, nil, body_774345)

var searchProvisionedProducts* = Call_SearchProvisionedProducts_774328(
    name: "searchProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts",
    validator: validate_SearchProvisionedProducts_774329, base: "/",
    url: url_SearchProvisionedProducts_774330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateProvisionedProduct_774346 = ref object of OpenApiRestCall_772597
proc url_TerminateProvisionedProduct_774348(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TerminateProvisionedProduct_774347(path: JsonNode; query: JsonNode;
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
  var valid_774349 = header.getOrDefault("X-Amz-Date")
  valid_774349 = validateParameter(valid_774349, JString, required = false,
                                 default = nil)
  if valid_774349 != nil:
    section.add "X-Amz-Date", valid_774349
  var valid_774350 = header.getOrDefault("X-Amz-Security-Token")
  valid_774350 = validateParameter(valid_774350, JString, required = false,
                                 default = nil)
  if valid_774350 != nil:
    section.add "X-Amz-Security-Token", valid_774350
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774351 = header.getOrDefault("X-Amz-Target")
  valid_774351 = validateParameter(valid_774351, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.TerminateProvisionedProduct"))
  if valid_774351 != nil:
    section.add "X-Amz-Target", valid_774351
  var valid_774352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774352 = validateParameter(valid_774352, JString, required = false,
                                 default = nil)
  if valid_774352 != nil:
    section.add "X-Amz-Content-Sha256", valid_774352
  var valid_774353 = header.getOrDefault("X-Amz-Algorithm")
  valid_774353 = validateParameter(valid_774353, JString, required = false,
                                 default = nil)
  if valid_774353 != nil:
    section.add "X-Amz-Algorithm", valid_774353
  var valid_774354 = header.getOrDefault("X-Amz-Signature")
  valid_774354 = validateParameter(valid_774354, JString, required = false,
                                 default = nil)
  if valid_774354 != nil:
    section.add "X-Amz-Signature", valid_774354
  var valid_774355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774355 = validateParameter(valid_774355, JString, required = false,
                                 default = nil)
  if valid_774355 != nil:
    section.add "X-Amz-SignedHeaders", valid_774355
  var valid_774356 = header.getOrDefault("X-Amz-Credential")
  valid_774356 = validateParameter(valid_774356, JString, required = false,
                                 default = nil)
  if valid_774356 != nil:
    section.add "X-Amz-Credential", valid_774356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774358: Call_TerminateProvisionedProduct_774346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_774358.validator(path, query, header, formData, body)
  let scheme = call_774358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774358.url(scheme.get, call_774358.host, call_774358.base,
                         call_774358.route, valid.getOrDefault("path"))
  result = hook(call_774358, url, valid)

proc call*(call_774359: Call_TerminateProvisionedProduct_774346; body: JsonNode): Recallable =
  ## terminateProvisionedProduct
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_774360 = newJObject()
  if body != nil:
    body_774360 = body
  result = call_774359.call(nil, nil, nil, nil, body_774360)

var terminateProvisionedProduct* = Call_TerminateProvisionedProduct_774346(
    name: "terminateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct",
    validator: validate_TerminateProvisionedProduct_774347, base: "/",
    url: url_TerminateProvisionedProduct_774348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConstraint_774361 = ref object of OpenApiRestCall_772597
proc url_UpdateConstraint_774363(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateConstraint_774362(path: JsonNode; query: JsonNode;
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
  var valid_774364 = header.getOrDefault("X-Amz-Date")
  valid_774364 = validateParameter(valid_774364, JString, required = false,
                                 default = nil)
  if valid_774364 != nil:
    section.add "X-Amz-Date", valid_774364
  var valid_774365 = header.getOrDefault("X-Amz-Security-Token")
  valid_774365 = validateParameter(valid_774365, JString, required = false,
                                 default = nil)
  if valid_774365 != nil:
    section.add "X-Amz-Security-Token", valid_774365
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774366 = header.getOrDefault("X-Amz-Target")
  valid_774366 = validateParameter(valid_774366, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateConstraint"))
  if valid_774366 != nil:
    section.add "X-Amz-Target", valid_774366
  var valid_774367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774367 = validateParameter(valid_774367, JString, required = false,
                                 default = nil)
  if valid_774367 != nil:
    section.add "X-Amz-Content-Sha256", valid_774367
  var valid_774368 = header.getOrDefault("X-Amz-Algorithm")
  valid_774368 = validateParameter(valid_774368, JString, required = false,
                                 default = nil)
  if valid_774368 != nil:
    section.add "X-Amz-Algorithm", valid_774368
  var valid_774369 = header.getOrDefault("X-Amz-Signature")
  valid_774369 = validateParameter(valid_774369, JString, required = false,
                                 default = nil)
  if valid_774369 != nil:
    section.add "X-Amz-Signature", valid_774369
  var valid_774370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774370 = validateParameter(valid_774370, JString, required = false,
                                 default = nil)
  if valid_774370 != nil:
    section.add "X-Amz-SignedHeaders", valid_774370
  var valid_774371 = header.getOrDefault("X-Amz-Credential")
  valid_774371 = validateParameter(valid_774371, JString, required = false,
                                 default = nil)
  if valid_774371 != nil:
    section.add "X-Amz-Credential", valid_774371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774373: Call_UpdateConstraint_774361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified constraint.
  ## 
  let valid = call_774373.validator(path, query, header, formData, body)
  let scheme = call_774373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774373.url(scheme.get, call_774373.host, call_774373.base,
                         call_774373.route, valid.getOrDefault("path"))
  result = hook(call_774373, url, valid)

proc call*(call_774374: Call_UpdateConstraint_774361; body: JsonNode): Recallable =
  ## updateConstraint
  ## Updates the specified constraint.
  ##   body: JObject (required)
  var body_774375 = newJObject()
  if body != nil:
    body_774375 = body
  result = call_774374.call(nil, nil, nil, nil, body_774375)

var updateConstraint* = Call_UpdateConstraint_774361(name: "updateConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint",
    validator: validate_UpdateConstraint_774362, base: "/",
    url: url_UpdateConstraint_774363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePortfolio_774376 = ref object of OpenApiRestCall_772597
proc url_UpdatePortfolio_774378(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdatePortfolio_774377(path: JsonNode; query: JsonNode;
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
  var valid_774379 = header.getOrDefault("X-Amz-Date")
  valid_774379 = validateParameter(valid_774379, JString, required = false,
                                 default = nil)
  if valid_774379 != nil:
    section.add "X-Amz-Date", valid_774379
  var valid_774380 = header.getOrDefault("X-Amz-Security-Token")
  valid_774380 = validateParameter(valid_774380, JString, required = false,
                                 default = nil)
  if valid_774380 != nil:
    section.add "X-Amz-Security-Token", valid_774380
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774381 = header.getOrDefault("X-Amz-Target")
  valid_774381 = validateParameter(valid_774381, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdatePortfolio"))
  if valid_774381 != nil:
    section.add "X-Amz-Target", valid_774381
  var valid_774382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774382 = validateParameter(valid_774382, JString, required = false,
                                 default = nil)
  if valid_774382 != nil:
    section.add "X-Amz-Content-Sha256", valid_774382
  var valid_774383 = header.getOrDefault("X-Amz-Algorithm")
  valid_774383 = validateParameter(valid_774383, JString, required = false,
                                 default = nil)
  if valid_774383 != nil:
    section.add "X-Amz-Algorithm", valid_774383
  var valid_774384 = header.getOrDefault("X-Amz-Signature")
  valid_774384 = validateParameter(valid_774384, JString, required = false,
                                 default = nil)
  if valid_774384 != nil:
    section.add "X-Amz-Signature", valid_774384
  var valid_774385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774385 = validateParameter(valid_774385, JString, required = false,
                                 default = nil)
  if valid_774385 != nil:
    section.add "X-Amz-SignedHeaders", valid_774385
  var valid_774386 = header.getOrDefault("X-Amz-Credential")
  valid_774386 = validateParameter(valid_774386, JString, required = false,
                                 default = nil)
  if valid_774386 != nil:
    section.add "X-Amz-Credential", valid_774386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774388: Call_UpdatePortfolio_774376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ## 
  let valid = call_774388.validator(path, query, header, formData, body)
  let scheme = call_774388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774388.url(scheme.get, call_774388.host, call_774388.base,
                         call_774388.route, valid.getOrDefault("path"))
  result = hook(call_774388, url, valid)

proc call*(call_774389: Call_UpdatePortfolio_774376; body: JsonNode): Recallable =
  ## updatePortfolio
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_774390 = newJObject()
  if body != nil:
    body_774390 = body
  result = call_774389.call(nil, nil, nil, nil, body_774390)

var updatePortfolio* = Call_UpdatePortfolio_774376(name: "updatePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio",
    validator: validate_UpdatePortfolio_774377, base: "/", url: url_UpdatePortfolio_774378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProduct_774391 = ref object of OpenApiRestCall_772597
proc url_UpdateProduct_774393(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateProduct_774392(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774394 = header.getOrDefault("X-Amz-Date")
  valid_774394 = validateParameter(valid_774394, JString, required = false,
                                 default = nil)
  if valid_774394 != nil:
    section.add "X-Amz-Date", valid_774394
  var valid_774395 = header.getOrDefault("X-Amz-Security-Token")
  valid_774395 = validateParameter(valid_774395, JString, required = false,
                                 default = nil)
  if valid_774395 != nil:
    section.add "X-Amz-Security-Token", valid_774395
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774396 = header.getOrDefault("X-Amz-Target")
  valid_774396 = validateParameter(valid_774396, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProduct"))
  if valid_774396 != nil:
    section.add "X-Amz-Target", valid_774396
  var valid_774397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774397 = validateParameter(valid_774397, JString, required = false,
                                 default = nil)
  if valid_774397 != nil:
    section.add "X-Amz-Content-Sha256", valid_774397
  var valid_774398 = header.getOrDefault("X-Amz-Algorithm")
  valid_774398 = validateParameter(valid_774398, JString, required = false,
                                 default = nil)
  if valid_774398 != nil:
    section.add "X-Amz-Algorithm", valid_774398
  var valid_774399 = header.getOrDefault("X-Amz-Signature")
  valid_774399 = validateParameter(valid_774399, JString, required = false,
                                 default = nil)
  if valid_774399 != nil:
    section.add "X-Amz-Signature", valid_774399
  var valid_774400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774400 = validateParameter(valid_774400, JString, required = false,
                                 default = nil)
  if valid_774400 != nil:
    section.add "X-Amz-SignedHeaders", valid_774400
  var valid_774401 = header.getOrDefault("X-Amz-Credential")
  valid_774401 = validateParameter(valid_774401, JString, required = false,
                                 default = nil)
  if valid_774401 != nil:
    section.add "X-Amz-Credential", valid_774401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774403: Call_UpdateProduct_774391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified product.
  ## 
  let valid = call_774403.validator(path, query, header, formData, body)
  let scheme = call_774403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774403.url(scheme.get, call_774403.host, call_774403.base,
                         call_774403.route, valid.getOrDefault("path"))
  result = hook(call_774403, url, valid)

proc call*(call_774404: Call_UpdateProduct_774391; body: JsonNode): Recallable =
  ## updateProduct
  ## Updates the specified product.
  ##   body: JObject (required)
  var body_774405 = newJObject()
  if body != nil:
    body_774405 = body
  result = call_774404.call(nil, nil, nil, nil, body_774405)

var updateProduct* = Call_UpdateProduct_774391(name: "updateProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct",
    validator: validate_UpdateProduct_774392, base: "/", url: url_UpdateProduct_774393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProduct_774406 = ref object of OpenApiRestCall_772597
proc url_UpdateProvisionedProduct_774408(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateProvisionedProduct_774407(path: JsonNode; query: JsonNode;
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
  var valid_774409 = header.getOrDefault("X-Amz-Date")
  valid_774409 = validateParameter(valid_774409, JString, required = false,
                                 default = nil)
  if valid_774409 != nil:
    section.add "X-Amz-Date", valid_774409
  var valid_774410 = header.getOrDefault("X-Amz-Security-Token")
  valid_774410 = validateParameter(valid_774410, JString, required = false,
                                 default = nil)
  if valid_774410 != nil:
    section.add "X-Amz-Security-Token", valid_774410
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774411 = header.getOrDefault("X-Amz-Target")
  valid_774411 = validateParameter(valid_774411, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProduct"))
  if valid_774411 != nil:
    section.add "X-Amz-Target", valid_774411
  var valid_774412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774412 = validateParameter(valid_774412, JString, required = false,
                                 default = nil)
  if valid_774412 != nil:
    section.add "X-Amz-Content-Sha256", valid_774412
  var valid_774413 = header.getOrDefault("X-Amz-Algorithm")
  valid_774413 = validateParameter(valid_774413, JString, required = false,
                                 default = nil)
  if valid_774413 != nil:
    section.add "X-Amz-Algorithm", valid_774413
  var valid_774414 = header.getOrDefault("X-Amz-Signature")
  valid_774414 = validateParameter(valid_774414, JString, required = false,
                                 default = nil)
  if valid_774414 != nil:
    section.add "X-Amz-Signature", valid_774414
  var valid_774415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774415 = validateParameter(valid_774415, JString, required = false,
                                 default = nil)
  if valid_774415 != nil:
    section.add "X-Amz-SignedHeaders", valid_774415
  var valid_774416 = header.getOrDefault("X-Amz-Credential")
  valid_774416 = validateParameter(valid_774416, JString, required = false,
                                 default = nil)
  if valid_774416 != nil:
    section.add "X-Amz-Credential", valid_774416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774418: Call_UpdateProvisionedProduct_774406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_774418.validator(path, query, header, formData, body)
  let scheme = call_774418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774418.url(scheme.get, call_774418.host, call_774418.base,
                         call_774418.route, valid.getOrDefault("path"))
  result = hook(call_774418, url, valid)

proc call*(call_774419: Call_UpdateProvisionedProduct_774406; body: JsonNode): Recallable =
  ## updateProvisionedProduct
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_774420 = newJObject()
  if body != nil:
    body_774420 = body
  result = call_774419.call(nil, nil, nil, nil, body_774420)

var updateProvisionedProduct* = Call_UpdateProvisionedProduct_774406(
    name: "updateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct",
    validator: validate_UpdateProvisionedProduct_774407, base: "/",
    url: url_UpdateProvisionedProduct_774408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProductProperties_774421 = ref object of OpenApiRestCall_772597
proc url_UpdateProvisionedProductProperties_774423(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateProvisionedProductProperties_774422(path: JsonNode;
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
  var valid_774424 = header.getOrDefault("X-Amz-Date")
  valid_774424 = validateParameter(valid_774424, JString, required = false,
                                 default = nil)
  if valid_774424 != nil:
    section.add "X-Amz-Date", valid_774424
  var valid_774425 = header.getOrDefault("X-Amz-Security-Token")
  valid_774425 = validateParameter(valid_774425, JString, required = false,
                                 default = nil)
  if valid_774425 != nil:
    section.add "X-Amz-Security-Token", valid_774425
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774426 = header.getOrDefault("X-Amz-Target")
  valid_774426 = validateParameter(valid_774426, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProductProperties"))
  if valid_774426 != nil:
    section.add "X-Amz-Target", valid_774426
  var valid_774427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774427 = validateParameter(valid_774427, JString, required = false,
                                 default = nil)
  if valid_774427 != nil:
    section.add "X-Amz-Content-Sha256", valid_774427
  var valid_774428 = header.getOrDefault("X-Amz-Algorithm")
  valid_774428 = validateParameter(valid_774428, JString, required = false,
                                 default = nil)
  if valid_774428 != nil:
    section.add "X-Amz-Algorithm", valid_774428
  var valid_774429 = header.getOrDefault("X-Amz-Signature")
  valid_774429 = validateParameter(valid_774429, JString, required = false,
                                 default = nil)
  if valid_774429 != nil:
    section.add "X-Amz-Signature", valid_774429
  var valid_774430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774430 = validateParameter(valid_774430, JString, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "X-Amz-SignedHeaders", valid_774430
  var valid_774431 = header.getOrDefault("X-Amz-Credential")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "X-Amz-Credential", valid_774431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774433: Call_UpdateProvisionedProductProperties_774421;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests updates to the properties of the specified provisioned product.
  ## 
  let valid = call_774433.validator(path, query, header, formData, body)
  let scheme = call_774433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774433.url(scheme.get, call_774433.host, call_774433.base,
                         call_774433.route, valid.getOrDefault("path"))
  result = hook(call_774433, url, valid)

proc call*(call_774434: Call_UpdateProvisionedProductProperties_774421;
          body: JsonNode): Recallable =
  ## updateProvisionedProductProperties
  ## Requests updates to the properties of the specified provisioned product.
  ##   body: JObject (required)
  var body_774435 = newJObject()
  if body != nil:
    body_774435 = body
  result = call_774434.call(nil, nil, nil, nil, body_774435)

var updateProvisionedProductProperties* = Call_UpdateProvisionedProductProperties_774421(
    name: "updateProvisionedProductProperties", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties",
    validator: validate_UpdateProvisionedProductProperties_774422, base: "/",
    url: url_UpdateProvisionedProductProperties_774423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisioningArtifact_774436 = ref object of OpenApiRestCall_772597
proc url_UpdateProvisioningArtifact_774438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateProvisioningArtifact_774437(path: JsonNode; query: JsonNode;
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
  var valid_774439 = header.getOrDefault("X-Amz-Date")
  valid_774439 = validateParameter(valid_774439, JString, required = false,
                                 default = nil)
  if valid_774439 != nil:
    section.add "X-Amz-Date", valid_774439
  var valid_774440 = header.getOrDefault("X-Amz-Security-Token")
  valid_774440 = validateParameter(valid_774440, JString, required = false,
                                 default = nil)
  if valid_774440 != nil:
    section.add "X-Amz-Security-Token", valid_774440
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774441 = header.getOrDefault("X-Amz-Target")
  valid_774441 = validateParameter(valid_774441, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisioningArtifact"))
  if valid_774441 != nil:
    section.add "X-Amz-Target", valid_774441
  var valid_774442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774442 = validateParameter(valid_774442, JString, required = false,
                                 default = nil)
  if valid_774442 != nil:
    section.add "X-Amz-Content-Sha256", valid_774442
  var valid_774443 = header.getOrDefault("X-Amz-Algorithm")
  valid_774443 = validateParameter(valid_774443, JString, required = false,
                                 default = nil)
  if valid_774443 != nil:
    section.add "X-Amz-Algorithm", valid_774443
  var valid_774444 = header.getOrDefault("X-Amz-Signature")
  valid_774444 = validateParameter(valid_774444, JString, required = false,
                                 default = nil)
  if valid_774444 != nil:
    section.add "X-Amz-Signature", valid_774444
  var valid_774445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774445 = validateParameter(valid_774445, JString, required = false,
                                 default = nil)
  if valid_774445 != nil:
    section.add "X-Amz-SignedHeaders", valid_774445
  var valid_774446 = header.getOrDefault("X-Amz-Credential")
  valid_774446 = validateParameter(valid_774446, JString, required = false,
                                 default = nil)
  if valid_774446 != nil:
    section.add "X-Amz-Credential", valid_774446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774448: Call_UpdateProvisioningArtifact_774436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_774448.validator(path, query, header, formData, body)
  let scheme = call_774448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774448.url(scheme.get, call_774448.host, call_774448.base,
                         call_774448.route, valid.getOrDefault("path"))
  result = hook(call_774448, url, valid)

proc call*(call_774449: Call_UpdateProvisioningArtifact_774436; body: JsonNode): Recallable =
  ## updateProvisioningArtifact
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_774450 = newJObject()
  if body != nil:
    body_774450 = body
  result = call_774449.call(nil, nil, nil, nil, body_774450)

var updateProvisioningArtifact* = Call_UpdateProvisioningArtifact_774436(
    name: "updateProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact",
    validator: validate_UpdateProvisioningArtifact_774437, base: "/",
    url: url_UpdateProvisioningArtifact_774438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceAction_774451 = ref object of OpenApiRestCall_772597
proc url_UpdateServiceAction_774453(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateServiceAction_774452(path: JsonNode; query: JsonNode;
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
  var valid_774454 = header.getOrDefault("X-Amz-Date")
  valid_774454 = validateParameter(valid_774454, JString, required = false,
                                 default = nil)
  if valid_774454 != nil:
    section.add "X-Amz-Date", valid_774454
  var valid_774455 = header.getOrDefault("X-Amz-Security-Token")
  valid_774455 = validateParameter(valid_774455, JString, required = false,
                                 default = nil)
  if valid_774455 != nil:
    section.add "X-Amz-Security-Token", valid_774455
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774456 = header.getOrDefault("X-Amz-Target")
  valid_774456 = validateParameter(valid_774456, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateServiceAction"))
  if valid_774456 != nil:
    section.add "X-Amz-Target", valid_774456
  var valid_774457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774457 = validateParameter(valid_774457, JString, required = false,
                                 default = nil)
  if valid_774457 != nil:
    section.add "X-Amz-Content-Sha256", valid_774457
  var valid_774458 = header.getOrDefault("X-Amz-Algorithm")
  valid_774458 = validateParameter(valid_774458, JString, required = false,
                                 default = nil)
  if valid_774458 != nil:
    section.add "X-Amz-Algorithm", valid_774458
  var valid_774459 = header.getOrDefault("X-Amz-Signature")
  valid_774459 = validateParameter(valid_774459, JString, required = false,
                                 default = nil)
  if valid_774459 != nil:
    section.add "X-Amz-Signature", valid_774459
  var valid_774460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774460 = validateParameter(valid_774460, JString, required = false,
                                 default = nil)
  if valid_774460 != nil:
    section.add "X-Amz-SignedHeaders", valid_774460
  var valid_774461 = header.getOrDefault("X-Amz-Credential")
  valid_774461 = validateParameter(valid_774461, JString, required = false,
                                 default = nil)
  if valid_774461 != nil:
    section.add "X-Amz-Credential", valid_774461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774463: Call_UpdateServiceAction_774451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a self-service action.
  ## 
  let valid = call_774463.validator(path, query, header, formData, body)
  let scheme = call_774463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774463.url(scheme.get, call_774463.host, call_774463.base,
                         call_774463.route, valid.getOrDefault("path"))
  result = hook(call_774463, url, valid)

proc call*(call_774464: Call_UpdateServiceAction_774451; body: JsonNode): Recallable =
  ## updateServiceAction
  ## Updates a self-service action.
  ##   body: JObject (required)
  var body_774465 = newJObject()
  if body != nil:
    body_774465 = body
  result = call_774464.call(nil, nil, nil, nil, body_774465)

var updateServiceAction* = Call_UpdateServiceAction_774451(
    name: "updateServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction",
    validator: validate_UpdateServiceAction_774452, base: "/",
    url: url_UpdateServiceAction_774453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagOption_774466 = ref object of OpenApiRestCall_772597
proc url_UpdateTagOption_774468(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTagOption_774467(path: JsonNode; query: JsonNode;
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
  var valid_774469 = header.getOrDefault("X-Amz-Date")
  valid_774469 = validateParameter(valid_774469, JString, required = false,
                                 default = nil)
  if valid_774469 != nil:
    section.add "X-Amz-Date", valid_774469
  var valid_774470 = header.getOrDefault("X-Amz-Security-Token")
  valid_774470 = validateParameter(valid_774470, JString, required = false,
                                 default = nil)
  if valid_774470 != nil:
    section.add "X-Amz-Security-Token", valid_774470
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774471 = header.getOrDefault("X-Amz-Target")
  valid_774471 = validateParameter(valid_774471, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateTagOption"))
  if valid_774471 != nil:
    section.add "X-Amz-Target", valid_774471
  var valid_774472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774472 = validateParameter(valid_774472, JString, required = false,
                                 default = nil)
  if valid_774472 != nil:
    section.add "X-Amz-Content-Sha256", valid_774472
  var valid_774473 = header.getOrDefault("X-Amz-Algorithm")
  valid_774473 = validateParameter(valid_774473, JString, required = false,
                                 default = nil)
  if valid_774473 != nil:
    section.add "X-Amz-Algorithm", valid_774473
  var valid_774474 = header.getOrDefault("X-Amz-Signature")
  valid_774474 = validateParameter(valid_774474, JString, required = false,
                                 default = nil)
  if valid_774474 != nil:
    section.add "X-Amz-Signature", valid_774474
  var valid_774475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774475 = validateParameter(valid_774475, JString, required = false,
                                 default = nil)
  if valid_774475 != nil:
    section.add "X-Amz-SignedHeaders", valid_774475
  var valid_774476 = header.getOrDefault("X-Amz-Credential")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "X-Amz-Credential", valid_774476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774478: Call_UpdateTagOption_774466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified TagOption.
  ## 
  let valid = call_774478.validator(path, query, header, formData, body)
  let scheme = call_774478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774478.url(scheme.get, call_774478.host, call_774478.base,
                         call_774478.route, valid.getOrDefault("path"))
  result = hook(call_774478, url, valid)

proc call*(call_774479: Call_UpdateTagOption_774466; body: JsonNode): Recallable =
  ## updateTagOption
  ## Updates the specified TagOption.
  ##   body: JObject (required)
  var body_774480 = newJObject()
  if body != nil:
    body_774480 = body
  result = call_774479.call(nil, nil, nil, nil, body_774480)

var updateTagOption* = Call_UpdateTagOption_774466(name: "updateTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption",
    validator: validate_UpdateTagOption_774467, base: "/", url: url_UpdateTagOption_774468,
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
