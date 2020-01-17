
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Cost Explorer Service
## version: 2017-10-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>The Cost Explorer API enables you to programmatically query your cost and usage data. You can query for aggregated data such as total monthly costs or total daily usage. You can also query for granular data, such as the number of daily write operations for Amazon DynamoDB database tables in your production environment. </p> <p>Service Endpoint</p> <p>The Cost Explorer API provides the following endpoint:</p> <ul> <li> <p> <code>https://ce.us-east-1.amazonaws.com</code> </p> </li> </ul> <p>For information about costs associated with the Cost Explorer API, see <a href="https://aws.amazon.com/aws-cost-management/pricing/">AWS Cost Management Pricing</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ce/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ce.ap-northeast-1.amazonaws.com",
                           "ap-southeast-1": "ce.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ce.us-west-2.amazonaws.com",
                           "eu-west-2": "ce.eu-west-2.amazonaws.com",
                           "ap-northeast-3": "ce.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ce.eu-central-1.amazonaws.com",
                           "us-east-2": "ce.us-east-2.amazonaws.com",
                           "us-east-1": "ce.us-east-1.amazonaws.com", "cn-northwest-1": "ce.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ce.ap-south-1.amazonaws.com",
                           "eu-north-1": "ce.eu-north-1.amazonaws.com",
                           "ap-northeast-2": "ce.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ce.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ce.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ce.eu-west-3.amazonaws.com",
                           "cn-north-1": "ce.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ce.sa-east-1.amazonaws.com",
                           "eu-west-1": "ce.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ce.us-gov-west-1.amazonaws.com",
                           "ap-southeast-2": "ce.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ce.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ce.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ce.ap-southeast-1.amazonaws.com",
      "us-west-2": "ce.us-west-2.amazonaws.com",
      "eu-west-2": "ce.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ce.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ce.eu-central-1.amazonaws.com",
      "us-east-2": "ce.us-east-2.amazonaws.com",
      "us-east-1": "ce.us-east-1.amazonaws.com",
      "cn-northwest-1": "ce.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ce.ap-south-1.amazonaws.com",
      "eu-north-1": "ce.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ce.ap-northeast-2.amazonaws.com",
      "us-west-1": "ce.us-west-1.amazonaws.com",
      "us-gov-east-1": "ce.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ce.eu-west-3.amazonaws.com",
      "cn-north-1": "ce.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ce.sa-east-1.amazonaws.com",
      "eu-west-1": "ce.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ce.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ce.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ce.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ce"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCostCategoryDefinition_605927 = ref object of OpenApiRestCall_605589
proc url_CreateCostCategoryDefinition_605929(protocol: Scheme; host: string;
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

proc validate_CreateCostCategoryDefinition_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Creates a new Cost Category with the requested name and rules.</p>
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "AWSInsightsIndexService.CreateCostCategoryDefinition"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_CreateCostCategoryDefinition_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Creates a new Cost Category with the requested name and rules.</p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_CreateCostCategoryDefinition_605927; body: JsonNode): Recallable =
  ## createCostCategoryDefinition
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Creates a new Cost Category with the requested name and rules.</p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var createCostCategoryDefinition* = Call_CreateCostCategoryDefinition_605927(
    name: "createCostCategoryDefinition", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.CreateCostCategoryDefinition",
    validator: validate_CreateCostCategoryDefinition_605928, base: "/",
    url: url_CreateCostCategoryDefinition_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCostCategoryDefinition_606196 = ref object of OpenApiRestCall_605589
proc url_DeleteCostCategoryDefinition_606198(protocol: Scheme; host: string;
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

proc validate_DeleteCostCategoryDefinition_606197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Deletes a Cost Category. Expenses from this month going forward will no longer be categorized with this Cost Category.</p>
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "AWSInsightsIndexService.DeleteCostCategoryDefinition"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_DeleteCostCategoryDefinition_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Deletes a Cost Category. Expenses from this month going forward will no longer be categorized with this Cost Category.</p>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_DeleteCostCategoryDefinition_606196; body: JsonNode): Recallable =
  ## deleteCostCategoryDefinition
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Deletes a Cost Category. Expenses from this month going forward will no longer be categorized with this Cost Category.</p>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var deleteCostCategoryDefinition* = Call_DeleteCostCategoryDefinition_606196(
    name: "deleteCostCategoryDefinition", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.DeleteCostCategoryDefinition",
    validator: validate_DeleteCostCategoryDefinition_606197, base: "/",
    url: url_DeleteCostCategoryDefinition_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCostCategoryDefinition_606211 = ref object of OpenApiRestCall_605589
proc url_DescribeCostCategoryDefinition_606213(protocol: Scheme; host: string;
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

proc validate_DescribeCostCategoryDefinition_606212(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN, rules, definition, and effective dates of a Cost Category that's defined in the account.</p> <p>You have the option to use <code>EffectiveOn</code> to return a Cost Category that is active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see a Cost Category that is effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "AWSInsightsIndexService.DescribeCostCategoryDefinition"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_DescribeCostCategoryDefinition_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN, rules, definition, and effective dates of a Cost Category that's defined in the account.</p> <p>You have the option to use <code>EffectiveOn</code> to return a Cost Category that is active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see a Cost Category that is effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_DescribeCostCategoryDefinition_606211; body: JsonNode): Recallable =
  ## describeCostCategoryDefinition
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN, rules, definition, and effective dates of a Cost Category that's defined in the account.</p> <p>You have the option to use <code>EffectiveOn</code> to return a Cost Category that is active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see a Cost Category that is effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var describeCostCategoryDefinition* = Call_DescribeCostCategoryDefinition_606211(
    name: "describeCostCategoryDefinition", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.DescribeCostCategoryDefinition",
    validator: validate_DescribeCostCategoryDefinition_606212, base: "/",
    url: url_DescribeCostCategoryDefinition_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCostAndUsage_606226 = ref object of OpenApiRestCall_605589
proc url_GetCostAndUsage_606228(protocol: Scheme; host: string; base: string;
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

proc validate_GetCostAndUsage_606227(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves cost and usage metrics for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts.
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetCostAndUsage"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_GetCostAndUsage_606226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves cost and usage metrics for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_GetCostAndUsage_606226; body: JsonNode): Recallable =
  ## getCostAndUsage
  ## Retrieves cost and usage metrics for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var getCostAndUsage* = Call_GetCostAndUsage_606226(name: "getCostAndUsage",
    meth: HttpMethod.HttpPost, host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetCostAndUsage",
    validator: validate_GetCostAndUsage_606227, base: "/", url: url_GetCostAndUsage_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCostAndUsageWithResources_606241 = ref object of OpenApiRestCall_605589
proc url_GetCostAndUsageWithResources_606243(protocol: Scheme; host: string;
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

proc validate_GetCostAndUsageWithResources_606242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves cost and usage metrics with resources for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts. This API is currently available for the Amazon Elastic Compute Cloud – Compute service only.</p> <note> <p>This is an opt-in only feature. You can enable this feature from the Cost Explorer Settings page. For information on how to access the Settings page, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-access.html">Controlling Access for Cost Explorer</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> </note>
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetCostAndUsageWithResources"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_GetCostAndUsageWithResources_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves cost and usage metrics with resources for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts. This API is currently available for the Amazon Elastic Compute Cloud – Compute service only.</p> <note> <p>This is an opt-in only feature. You can enable this feature from the Cost Explorer Settings page. For information on how to access the Settings page, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-access.html">Controlling Access for Cost Explorer</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> </note>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_GetCostAndUsageWithResources_606241; body: JsonNode): Recallable =
  ## getCostAndUsageWithResources
  ## <p>Retrieves cost and usage metrics with resources for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts. This API is currently available for the Amazon Elastic Compute Cloud – Compute service only.</p> <note> <p>This is an opt-in only feature. You can enable this feature from the Cost Explorer Settings page. For information on how to access the Settings page, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-access.html">Controlling Access for Cost Explorer</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var getCostAndUsageWithResources* = Call_GetCostAndUsageWithResources_606241(
    name: "getCostAndUsageWithResources", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetCostAndUsageWithResources",
    validator: validate_GetCostAndUsageWithResources_606242, base: "/",
    url: url_GetCostAndUsageWithResources_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCostForecast_606256 = ref object of OpenApiRestCall_605589
proc url_GetCostForecast_606258(protocol: Scheme; host: string; base: string;
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

proc validate_GetCostForecast_606257(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will spend over the forecast time period that you select, based on your past costs. 
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetCostForecast"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_GetCostForecast_606256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will spend over the forecast time period that you select, based on your past costs. 
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_GetCostForecast_606256; body: JsonNode): Recallable =
  ## getCostForecast
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will spend over the forecast time period that you select, based on your past costs. 
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var getCostForecast* = Call_GetCostForecast_606256(name: "getCostForecast",
    meth: HttpMethod.HttpPost, host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetCostForecast",
    validator: validate_GetCostForecast_606257, base: "/", url: url_GetCostForecast_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDimensionValues_606271 = ref object of OpenApiRestCall_605589
proc url_GetDimensionValues_606273(protocol: Scheme; host: string; base: string;
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

proc validate_GetDimensionValues_606272(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves all available filter values for a specified filter over a period of time. You can search the dimension values for an arbitrary string. 
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetDimensionValues"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_GetDimensionValues_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all available filter values for a specified filter over a period of time. You can search the dimension values for an arbitrary string. 
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_GetDimensionValues_606271; body: JsonNode): Recallable =
  ## getDimensionValues
  ## Retrieves all available filter values for a specified filter over a period of time. You can search the dimension values for an arbitrary string. 
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var getDimensionValues* = Call_GetDimensionValues_606271(
    name: "getDimensionValues", meth: HttpMethod.HttpPost, host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetDimensionValues",
    validator: validate_GetDimensionValues_606272, base: "/",
    url: url_GetDimensionValues_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReservationCoverage_606286 = ref object of OpenApiRestCall_605589
proc url_GetReservationCoverage_606288(protocol: Scheme; host: string; base: string;
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

proc validate_GetReservationCoverage_606287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the reservation coverage for your account. This enables you to see how much of your Amazon Elastic Compute Cloud, Amazon ElastiCache, Amazon Relational Database Service, or Amazon Redshift usage is covered by a reservation. An organization's master account can see the coverage of the associated member accounts. For any time period, you can filter data about reservation usage by the following dimensions:</p> <ul> <li> <p>AZ</p> </li> <li> <p>CACHE_ENGINE</p> </li> <li> <p>DATABASE_ENGINE</p> </li> <li> <p>DEPLOYMENT_OPTION</p> </li> <li> <p>INSTANCE_TYPE</p> </li> <li> <p>LINKED_ACCOUNT</p> </li> <li> <p>OPERATING_SYSTEM</p> </li> <li> <p>PLATFORM</p> </li> <li> <p>REGION</p> </li> <li> <p>SERVICE</p> </li> <li> <p>TAG</p> </li> <li> <p>TENANCY</p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation. </p>
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetReservationCoverage"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_GetReservationCoverage_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the reservation coverage for your account. This enables you to see how much of your Amazon Elastic Compute Cloud, Amazon ElastiCache, Amazon Relational Database Service, or Amazon Redshift usage is covered by a reservation. An organization's master account can see the coverage of the associated member accounts. For any time period, you can filter data about reservation usage by the following dimensions:</p> <ul> <li> <p>AZ</p> </li> <li> <p>CACHE_ENGINE</p> </li> <li> <p>DATABASE_ENGINE</p> </li> <li> <p>DEPLOYMENT_OPTION</p> </li> <li> <p>INSTANCE_TYPE</p> </li> <li> <p>LINKED_ACCOUNT</p> </li> <li> <p>OPERATING_SYSTEM</p> </li> <li> <p>PLATFORM</p> </li> <li> <p>REGION</p> </li> <li> <p>SERVICE</p> </li> <li> <p>TAG</p> </li> <li> <p>TENANCY</p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation. </p>
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_GetReservationCoverage_606286; body: JsonNode): Recallable =
  ## getReservationCoverage
  ## <p>Retrieves the reservation coverage for your account. This enables you to see how much of your Amazon Elastic Compute Cloud, Amazon ElastiCache, Amazon Relational Database Service, or Amazon Redshift usage is covered by a reservation. An organization's master account can see the coverage of the associated member accounts. For any time period, you can filter data about reservation usage by the following dimensions:</p> <ul> <li> <p>AZ</p> </li> <li> <p>CACHE_ENGINE</p> </li> <li> <p>DATABASE_ENGINE</p> </li> <li> <p>DEPLOYMENT_OPTION</p> </li> <li> <p>INSTANCE_TYPE</p> </li> <li> <p>LINKED_ACCOUNT</p> </li> <li> <p>OPERATING_SYSTEM</p> </li> <li> <p>PLATFORM</p> </li> <li> <p>REGION</p> </li> <li> <p>SERVICE</p> </li> <li> <p>TAG</p> </li> <li> <p>TENANCY</p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation. </p>
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var getReservationCoverage* = Call_GetReservationCoverage_606286(
    name: "getReservationCoverage", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetReservationCoverage",
    validator: validate_GetReservationCoverage_606287, base: "/",
    url: url_GetReservationCoverage_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReservationPurchaseRecommendation_606301 = ref object of OpenApiRestCall_605589
proc url_GetReservationPurchaseRecommendation_606303(protocol: Scheme;
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

proc validate_GetReservationPurchaseRecommendation_606302(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets recommendations for which reservations to purchase. These recommendations could help you reduce your costs. Reservations provide a discounted hourly rate (up to 75%) compared to On-Demand pricing.</p> <p>AWS generates your recommendations by identifying your On-Demand usage during a specific time period and collecting your usage into categories that are eligible for a reservation. After AWS has these categories, it simulates every combination of reservations in each category of usage to identify the best number of each type of RI to purchase to maximize your estimated savings. </p> <p>For example, AWS automatically aggregates your Amazon EC2 Linux, shared tenancy, and c4 family usage in the US West (Oregon) Region and recommends that you buy size-flexible regional reservations to apply to the c4 family usage. AWS recommends the smallest size instance in an instance family. This makes it easier to purchase a size-flexible RI. AWS also shows the equal number of normalized units so that you can purchase any instance size that you want. For this example, your RI recommendation would be for <code>c4.large</code> because that is the smallest size instance in the c4 instance family.</p>
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
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetReservationPurchaseRecommendation"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_GetReservationPurchaseRecommendation_606301;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets recommendations for which reservations to purchase. These recommendations could help you reduce your costs. Reservations provide a discounted hourly rate (up to 75%) compared to On-Demand pricing.</p> <p>AWS generates your recommendations by identifying your On-Demand usage during a specific time period and collecting your usage into categories that are eligible for a reservation. After AWS has these categories, it simulates every combination of reservations in each category of usage to identify the best number of each type of RI to purchase to maximize your estimated savings. </p> <p>For example, AWS automatically aggregates your Amazon EC2 Linux, shared tenancy, and c4 family usage in the US West (Oregon) Region and recommends that you buy size-flexible regional reservations to apply to the c4 family usage. AWS recommends the smallest size instance in an instance family. This makes it easier to purchase a size-flexible RI. AWS also shows the equal number of normalized units so that you can purchase any instance size that you want. For this example, your RI recommendation would be for <code>c4.large</code> because that is the smallest size instance in the c4 instance family.</p>
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_GetReservationPurchaseRecommendation_606301;
          body: JsonNode): Recallable =
  ## getReservationPurchaseRecommendation
  ## <p>Gets recommendations for which reservations to purchase. These recommendations could help you reduce your costs. Reservations provide a discounted hourly rate (up to 75%) compared to On-Demand pricing.</p> <p>AWS generates your recommendations by identifying your On-Demand usage during a specific time period and collecting your usage into categories that are eligible for a reservation. After AWS has these categories, it simulates every combination of reservations in each category of usage to identify the best number of each type of RI to purchase to maximize your estimated savings. </p> <p>For example, AWS automatically aggregates your Amazon EC2 Linux, shared tenancy, and c4 family usage in the US West (Oregon) Region and recommends that you buy size-flexible regional reservations to apply to the c4 family usage. AWS recommends the smallest size instance in an instance family. This makes it easier to purchase a size-flexible RI. AWS also shows the equal number of normalized units so that you can purchase any instance size that you want. For this example, your RI recommendation would be for <code>c4.large</code> because that is the smallest size instance in the c4 instance family.</p>
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var getReservationPurchaseRecommendation* = Call_GetReservationPurchaseRecommendation_606301(
    name: "getReservationPurchaseRecommendation", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetReservationPurchaseRecommendation",
    validator: validate_GetReservationPurchaseRecommendation_606302, base: "/",
    url: url_GetReservationPurchaseRecommendation_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReservationUtilization_606316 = ref object of OpenApiRestCall_605589
proc url_GetReservationUtilization_606318(protocol: Scheme; host: string;
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

proc validate_GetReservationUtilization_606317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the reservation utilization for your account. Master accounts in an organization have access to member accounts. You can filter data by dimensions in a time period. You can use <code>GetDimensionValues</code> to determine the possible dimension values. Currently, you can group only by <code>SUBSCRIPTION_ID</code>. 
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
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetReservationUtilization"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_GetReservationUtilization_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the reservation utilization for your account. Master accounts in an organization have access to member accounts. You can filter data by dimensions in a time period. You can use <code>GetDimensionValues</code> to determine the possible dimension values. Currently, you can group only by <code>SUBSCRIPTION_ID</code>. 
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_GetReservationUtilization_606316; body: JsonNode): Recallable =
  ## getReservationUtilization
  ## Retrieves the reservation utilization for your account. Master accounts in an organization have access to member accounts. You can filter data by dimensions in a time period. You can use <code>GetDimensionValues</code> to determine the possible dimension values. Currently, you can group only by <code>SUBSCRIPTION_ID</code>. 
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var getReservationUtilization* = Call_GetReservationUtilization_606316(
    name: "getReservationUtilization", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetReservationUtilization",
    validator: validate_GetReservationUtilization_606317, base: "/",
    url: url_GetReservationUtilization_606318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRightsizingRecommendation_606331 = ref object of OpenApiRestCall_605589
proc url_GetRightsizingRecommendation_606333(protocol: Scheme; host: string;
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

proc validate_GetRightsizingRecommendation_606332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates recommendations that helps you save cost by identifying idle and underutilized Amazon EC2 instances.</p> <p>Recommendations are generated to either downsize or terminate instances, along with providing savings detail and metrics. For details on calculation and function, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-what-is.html">Optimizing Your Cost with Rightsizing Recommendations</a>.</p>
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
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetRightsizingRecommendation"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_GetRightsizingRecommendation_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates recommendations that helps you save cost by identifying idle and underutilized Amazon EC2 instances.</p> <p>Recommendations are generated to either downsize or terminate instances, along with providing savings detail and metrics. For details on calculation and function, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-what-is.html">Optimizing Your Cost with Rightsizing Recommendations</a>.</p>
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_GetRightsizingRecommendation_606331; body: JsonNode): Recallable =
  ## getRightsizingRecommendation
  ## <p>Creates recommendations that helps you save cost by identifying idle and underutilized Amazon EC2 instances.</p> <p>Recommendations are generated to either downsize or terminate instances, along with providing savings detail and metrics. For details on calculation and function, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-what-is.html">Optimizing Your Cost with Rightsizing Recommendations</a>.</p>
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var getRightsizingRecommendation* = Call_GetRightsizingRecommendation_606331(
    name: "getRightsizingRecommendation", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetRightsizingRecommendation",
    validator: validate_GetRightsizingRecommendation_606332, base: "/",
    url: url_GetRightsizingRecommendation_606333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSavingsPlansCoverage_606346 = ref object of OpenApiRestCall_605589
proc url_GetSavingsPlansCoverage_606348(protocol: Scheme; host: string; base: string;
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

proc validate_GetSavingsPlansCoverage_606347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the Savings Plans covered for your account. This enables you to see how much of your cost is covered by a Savings Plan. An organization’s master account can see the coverage of the associated member accounts. For any time period, you can filter data for Savings Plans usage with the following dimensions:</p> <ul> <li> <p> <code>LINKED_ACCOUNT</code> </p> </li> <li> <p> <code>REGION</code> </p> </li> <li> <p> <code>SERVICE</code> </p> </li> <li> <p> <code>INSTANCE_FAMILY</code> </p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606349 = query.getOrDefault("MaxResults")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "MaxResults", valid_606349
  var valid_606350 = query.getOrDefault("NextToken")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "NextToken", valid_606350
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
  var valid_606351 = header.getOrDefault("X-Amz-Target")
  valid_606351 = validateParameter(valid_606351, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetSavingsPlansCoverage"))
  if valid_606351 != nil:
    section.add "X-Amz-Target", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Signature")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Signature", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Content-Sha256", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Date")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Date", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Credential")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Credential", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Security-Token")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Security-Token", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Algorithm")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Algorithm", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-SignedHeaders", valid_606358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606360: Call_GetSavingsPlansCoverage_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the Savings Plans covered for your account. This enables you to see how much of your cost is covered by a Savings Plan. An organization’s master account can see the coverage of the associated member accounts. For any time period, you can filter data for Savings Plans usage with the following dimensions:</p> <ul> <li> <p> <code>LINKED_ACCOUNT</code> </p> </li> <li> <p> <code>REGION</code> </p> </li> <li> <p> <code>SERVICE</code> </p> </li> <li> <p> <code>INSTANCE_FAMILY</code> </p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation.</p>
  ## 
  let valid = call_606360.validator(path, query, header, formData, body)
  let scheme = call_606360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606360.url(scheme.get, call_606360.host, call_606360.base,
                         call_606360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606360, url, valid)

proc call*(call_606361: Call_GetSavingsPlansCoverage_606346; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSavingsPlansCoverage
  ## <p>Retrieves the Savings Plans covered for your account. This enables you to see how much of your cost is covered by a Savings Plan. An organization’s master account can see the coverage of the associated member accounts. For any time period, you can filter data for Savings Plans usage with the following dimensions:</p> <ul> <li> <p> <code>LINKED_ACCOUNT</code> </p> </li> <li> <p> <code>REGION</code> </p> </li> <li> <p> <code>SERVICE</code> </p> </li> <li> <p> <code>INSTANCE_FAMILY</code> </p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606362 = newJObject()
  var body_606363 = newJObject()
  add(query_606362, "MaxResults", newJString(MaxResults))
  add(query_606362, "NextToken", newJString(NextToken))
  if body != nil:
    body_606363 = body
  result = call_606361.call(nil, query_606362, nil, nil, body_606363)

var getSavingsPlansCoverage* = Call_GetSavingsPlansCoverage_606346(
    name: "getSavingsPlansCoverage", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansCoverage",
    validator: validate_GetSavingsPlansCoverage_606347, base: "/",
    url: url_GetSavingsPlansCoverage_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSavingsPlansPurchaseRecommendation_606365 = ref object of OpenApiRestCall_605589
proc url_GetSavingsPlansPurchaseRecommendation_606367(protocol: Scheme;
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

proc validate_GetSavingsPlansPurchaseRecommendation_606366(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves your request parameters, Savings Plan Recommendations Summary and Details.
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
  var valid_606368 = header.getOrDefault("X-Amz-Target")
  valid_606368 = validateParameter(valid_606368, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation"))
  if valid_606368 != nil:
    section.add "X-Amz-Target", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Signature")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Signature", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Content-Sha256", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Date")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Date", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Credential")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Credential", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Security-Token")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Security-Token", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Algorithm")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Algorithm", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-SignedHeaders", valid_606375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606377: Call_GetSavingsPlansPurchaseRecommendation_606365;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves your request parameters, Savings Plan Recommendations Summary and Details.
  ## 
  let valid = call_606377.validator(path, query, header, formData, body)
  let scheme = call_606377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606377.url(scheme.get, call_606377.host, call_606377.base,
                         call_606377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606377, url, valid)

proc call*(call_606378: Call_GetSavingsPlansPurchaseRecommendation_606365;
          body: JsonNode): Recallable =
  ## getSavingsPlansPurchaseRecommendation
  ## Retrieves your request parameters, Savings Plan Recommendations Summary and Details.
  ##   body: JObject (required)
  var body_606379 = newJObject()
  if body != nil:
    body_606379 = body
  result = call_606378.call(nil, nil, nil, nil, body_606379)

var getSavingsPlansPurchaseRecommendation* = Call_GetSavingsPlansPurchaseRecommendation_606365(
    name: "getSavingsPlansPurchaseRecommendation", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation",
    validator: validate_GetSavingsPlansPurchaseRecommendation_606366, base: "/",
    url: url_GetSavingsPlansPurchaseRecommendation_606367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSavingsPlansUtilization_606380 = ref object of OpenApiRestCall_605589
proc url_GetSavingsPlansUtilization_606382(protocol: Scheme; host: string;
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

proc validate_GetSavingsPlansUtilization_606381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the Savings Plans utilization for your account across date ranges with daily or monthly granularity. Master accounts in an organization have access to member accounts. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p>You cannot group by any dimension values for <code>GetSavingsPlansUtilization</code>.</p> </note>
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
  var valid_606383 = header.getOrDefault("X-Amz-Target")
  valid_606383 = validateParameter(valid_606383, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetSavingsPlansUtilization"))
  if valid_606383 != nil:
    section.add "X-Amz-Target", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Signature")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Signature", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Content-Sha256", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Date")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Date", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Credential")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Credential", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Security-Token")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Security-Token", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Algorithm")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Algorithm", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-SignedHeaders", valid_606390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606392: Call_GetSavingsPlansUtilization_606380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the Savings Plans utilization for your account across date ranges with daily or monthly granularity. Master accounts in an organization have access to member accounts. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p>You cannot group by any dimension values for <code>GetSavingsPlansUtilization</code>.</p> </note>
  ## 
  let valid = call_606392.validator(path, query, header, formData, body)
  let scheme = call_606392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606392.url(scheme.get, call_606392.host, call_606392.base,
                         call_606392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606392, url, valid)

proc call*(call_606393: Call_GetSavingsPlansUtilization_606380; body: JsonNode): Recallable =
  ## getSavingsPlansUtilization
  ## <p>Retrieves the Savings Plans utilization for your account across date ranges with daily or monthly granularity. Master accounts in an organization have access to member accounts. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p>You cannot group by any dimension values for <code>GetSavingsPlansUtilization</code>.</p> </note>
  ##   body: JObject (required)
  var body_606394 = newJObject()
  if body != nil:
    body_606394 = body
  result = call_606393.call(nil, nil, nil, nil, body_606394)

var getSavingsPlansUtilization* = Call_GetSavingsPlansUtilization_606380(
    name: "getSavingsPlansUtilization", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansUtilization",
    validator: validate_GetSavingsPlansUtilization_606381, base: "/",
    url: url_GetSavingsPlansUtilization_606382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSavingsPlansUtilizationDetails_606395 = ref object of OpenApiRestCall_605589
proc url_GetSavingsPlansUtilizationDetails_606397(protocol: Scheme; host: string;
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

proc validate_GetSavingsPlansUtilizationDetails_606396(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves attribute data along with aggregate utilization and savings data for a given time period. This doesn't support granular or grouped data (daily/monthly) in response. You can't retrieve data by dates in a single response similar to <code>GetSavingsPlanUtilization</code>, but you have the option to make multiple calls to <code>GetSavingsPlanUtilizationDetails</code> by providing individual dates. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p> <code>GetSavingsPlanUtilizationDetails</code> internally groups data by <code>SavingsPlansArn</code>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606398 = query.getOrDefault("MaxResults")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "MaxResults", valid_606398
  var valid_606399 = query.getOrDefault("NextToken")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "NextToken", valid_606399
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
  var valid_606400 = header.getOrDefault("X-Amz-Target")
  valid_606400 = validateParameter(valid_606400, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetSavingsPlansUtilizationDetails"))
  if valid_606400 != nil:
    section.add "X-Amz-Target", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Signature")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Signature", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Content-Sha256", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Date")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Date", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Credential")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Credential", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Security-Token")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Security-Token", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Algorithm")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Algorithm", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-SignedHeaders", valid_606407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606409: Call_GetSavingsPlansUtilizationDetails_606395;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves attribute data along with aggregate utilization and savings data for a given time period. This doesn't support granular or grouped data (daily/monthly) in response. You can't retrieve data by dates in a single response similar to <code>GetSavingsPlanUtilization</code>, but you have the option to make multiple calls to <code>GetSavingsPlanUtilizationDetails</code> by providing individual dates. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p> <code>GetSavingsPlanUtilizationDetails</code> internally groups data by <code>SavingsPlansArn</code>.</p> </note>
  ## 
  let valid = call_606409.validator(path, query, header, formData, body)
  let scheme = call_606409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606409.url(scheme.get, call_606409.host, call_606409.base,
                         call_606409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606409, url, valid)

proc call*(call_606410: Call_GetSavingsPlansUtilizationDetails_606395;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSavingsPlansUtilizationDetails
  ## <p>Retrieves attribute data along with aggregate utilization and savings data for a given time period. This doesn't support granular or grouped data (daily/monthly) in response. You can't retrieve data by dates in a single response similar to <code>GetSavingsPlanUtilization</code>, but you have the option to make multiple calls to <code>GetSavingsPlanUtilizationDetails</code> by providing individual dates. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p> <code>GetSavingsPlanUtilizationDetails</code> internally groups data by <code>SavingsPlansArn</code>.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606411 = newJObject()
  var body_606412 = newJObject()
  add(query_606411, "MaxResults", newJString(MaxResults))
  add(query_606411, "NextToken", newJString(NextToken))
  if body != nil:
    body_606412 = body
  result = call_606410.call(nil, query_606411, nil, nil, body_606412)

var getSavingsPlansUtilizationDetails* = Call_GetSavingsPlansUtilizationDetails_606395(
    name: "getSavingsPlansUtilizationDetails", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansUtilizationDetails",
    validator: validate_GetSavingsPlansUtilizationDetails_606396, base: "/",
    url: url_GetSavingsPlansUtilizationDetails_606397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_606413 = ref object of OpenApiRestCall_605589
proc url_GetTags_606415(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTags_606414(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Queries for available tag keys and tag values for a specified period. You can search the tag values for an arbitrary string. 
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
  var valid_606416 = header.getOrDefault("X-Amz-Target")
  valid_606416 = validateParameter(valid_606416, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetTags"))
  if valid_606416 != nil:
    section.add "X-Amz-Target", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Signature")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Signature", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Content-Sha256", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Date")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Date", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Credential")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Credential", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Security-Token")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Security-Token", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Algorithm")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Algorithm", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-SignedHeaders", valid_606423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606425: Call_GetTags_606413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Queries for available tag keys and tag values for a specified period. You can search the tag values for an arbitrary string. 
  ## 
  let valid = call_606425.validator(path, query, header, formData, body)
  let scheme = call_606425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606425.url(scheme.get, call_606425.host, call_606425.base,
                         call_606425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606425, url, valid)

proc call*(call_606426: Call_GetTags_606413; body: JsonNode): Recallable =
  ## getTags
  ## Queries for available tag keys and tag values for a specified period. You can search the tag values for an arbitrary string. 
  ##   body: JObject (required)
  var body_606427 = newJObject()
  if body != nil:
    body_606427 = body
  result = call_606426.call(nil, nil, nil, nil, body_606427)

var getTags* = Call_GetTags_606413(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetTags",
                                validator: validate_GetTags_606414, base: "/",
                                url: url_GetTags_606415,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsageForecast_606428 = ref object of OpenApiRestCall_605589
proc url_GetUsageForecast_606430(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsageForecast_606429(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will use over the forecast time period that you select, based on your past usage. 
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
  var valid_606431 = header.getOrDefault("X-Amz-Target")
  valid_606431 = validateParameter(valid_606431, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetUsageForecast"))
  if valid_606431 != nil:
    section.add "X-Amz-Target", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Signature")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Signature", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Content-Sha256", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Date")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Date", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Credential")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Credential", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Security-Token")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Security-Token", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Algorithm")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Algorithm", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-SignedHeaders", valid_606438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606440: Call_GetUsageForecast_606428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will use over the forecast time period that you select, based on your past usage. 
  ## 
  let valid = call_606440.validator(path, query, header, formData, body)
  let scheme = call_606440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606440.url(scheme.get, call_606440.host, call_606440.base,
                         call_606440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606440, url, valid)

proc call*(call_606441: Call_GetUsageForecast_606428; body: JsonNode): Recallable =
  ## getUsageForecast
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will use over the forecast time period that you select, based on your past usage. 
  ##   body: JObject (required)
  var body_606442 = newJObject()
  if body != nil:
    body_606442 = body
  result = call_606441.call(nil, nil, nil, nil, body_606442)

var getUsageForecast* = Call_GetUsageForecast_606428(name: "getUsageForecast",
    meth: HttpMethod.HttpPost, host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetUsageForecast",
    validator: validate_GetUsageForecast_606429, base: "/",
    url: url_GetUsageForecast_606430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCostCategoryDefinitions_606443 = ref object of OpenApiRestCall_605589
proc url_ListCostCategoryDefinitions_606445(protocol: Scheme; host: string;
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

proc validate_ListCostCategoryDefinitions_606444(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN and effective dates of all Cost Categories defined in the account. You have the option to use <code>EffectiveOn</code> to return a list of Cost Categories that were active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see Cost Categories that are effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
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
  var valid_606446 = header.getOrDefault("X-Amz-Target")
  valid_606446 = validateParameter(valid_606446, JString, required = true, default = newJString(
      "AWSInsightsIndexService.ListCostCategoryDefinitions"))
  if valid_606446 != nil:
    section.add "X-Amz-Target", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Signature")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Signature", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Content-Sha256", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Date")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Date", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Credential")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Credential", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Security-Token")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Security-Token", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Algorithm")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Algorithm", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-SignedHeaders", valid_606453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606455: Call_ListCostCategoryDefinitions_606443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN and effective dates of all Cost Categories defined in the account. You have the option to use <code>EffectiveOn</code> to return a list of Cost Categories that were active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see Cost Categories that are effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ## 
  let valid = call_606455.validator(path, query, header, formData, body)
  let scheme = call_606455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606455.url(scheme.get, call_606455.host, call_606455.base,
                         call_606455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606455, url, valid)

proc call*(call_606456: Call_ListCostCategoryDefinitions_606443; body: JsonNode): Recallable =
  ## listCostCategoryDefinitions
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN and effective dates of all Cost Categories defined in the account. You have the option to use <code>EffectiveOn</code> to return a list of Cost Categories that were active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see Cost Categories that are effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ##   body: JObject (required)
  var body_606457 = newJObject()
  if body != nil:
    body_606457 = body
  result = call_606456.call(nil, nil, nil, nil, body_606457)

var listCostCategoryDefinitions* = Call_ListCostCategoryDefinitions_606443(
    name: "listCostCategoryDefinitions", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.ListCostCategoryDefinitions",
    validator: validate_ListCostCategoryDefinitions_606444, base: "/",
    url: url_ListCostCategoryDefinitions_606445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCostCategoryDefinition_606458 = ref object of OpenApiRestCall_605589
proc url_UpdateCostCategoryDefinition_606460(protocol: Scheme; host: string;
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

proc validate_UpdateCostCategoryDefinition_606459(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Updates an existing Cost Category. Changes made to the Cost Category rules will be used to categorize the current month’s expenses and future expenses. This won’t change categorization for the previous months.</p>
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
  var valid_606461 = header.getOrDefault("X-Amz-Target")
  valid_606461 = validateParameter(valid_606461, JString, required = true, default = newJString(
      "AWSInsightsIndexService.UpdateCostCategoryDefinition"))
  if valid_606461 != nil:
    section.add "X-Amz-Target", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Signature")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Signature", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Content-Sha256", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Date")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Date", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Credential")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Credential", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Security-Token")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Security-Token", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Algorithm")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Algorithm", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-SignedHeaders", valid_606468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606470: Call_UpdateCostCategoryDefinition_606458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Updates an existing Cost Category. Changes made to the Cost Category rules will be used to categorize the current month’s expenses and future expenses. This won’t change categorization for the previous months.</p>
  ## 
  let valid = call_606470.validator(path, query, header, formData, body)
  let scheme = call_606470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606470.url(scheme.get, call_606470.host, call_606470.base,
                         call_606470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606470, url, valid)

proc call*(call_606471: Call_UpdateCostCategoryDefinition_606458; body: JsonNode): Recallable =
  ## updateCostCategoryDefinition
  ## <important> <p> <i> <b>Cost Category is in public beta for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Updates an existing Cost Category. Changes made to the Cost Category rules will be used to categorize the current month’s expenses and future expenses. This won’t change categorization for the previous months.</p>
  ##   body: JObject (required)
  var body_606472 = newJObject()
  if body != nil:
    body_606472 = body
  result = call_606471.call(nil, nil, nil, nil, body_606472)

var updateCostCategoryDefinition* = Call_UpdateCostCategoryDefinition_606458(
    name: "updateCostCategoryDefinition", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.UpdateCostCategoryDefinition",
    validator: validate_UpdateCostCategoryDefinition_606459, base: "/",
    url: url_UpdateCostCategoryDefinition_606460,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
