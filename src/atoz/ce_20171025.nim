
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
  Call_CreateCostCategoryDefinition_599705 = ref object of OpenApiRestCall_599368
proc url_CreateCostCategoryDefinition_599707(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCostCategoryDefinition_599706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Creates a new Cost Category with the requested name and rules.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
      "AWSInsightsIndexService.CreateCostCategoryDefinition"))
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

proc call*(call_599863: Call_CreateCostCategoryDefinition_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Creates a new Cost Category with the requested name and rules.</p>
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_CreateCostCategoryDefinition_599705; body: JsonNode): Recallable =
  ## createCostCategoryDefinition
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Creates a new Cost Category with the requested name and rules.</p>
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var createCostCategoryDefinition* = Call_CreateCostCategoryDefinition_599705(
    name: "createCostCategoryDefinition", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.CreateCostCategoryDefinition",
    validator: validate_CreateCostCategoryDefinition_599706, base: "/",
    url: url_CreateCostCategoryDefinition_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCostCategoryDefinition_599974 = ref object of OpenApiRestCall_599368
proc url_DeleteCostCategoryDefinition_599976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCostCategoryDefinition_599975(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Deletes a Cost Category. Expenses from this month going forward will no longer be categorized with this Cost Category.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
      "AWSInsightsIndexService.DeleteCostCategoryDefinition"))
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

proc call*(call_599986: Call_DeleteCostCategoryDefinition_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Deletes a Cost Category. Expenses from this month going forward will no longer be categorized with this Cost Category.</p>
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_DeleteCostCategoryDefinition_599974; body: JsonNode): Recallable =
  ## deleteCostCategoryDefinition
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Deletes a Cost Category. Expenses from this month going forward will no longer be categorized with this Cost Category.</p>
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var deleteCostCategoryDefinition* = Call_DeleteCostCategoryDefinition_599974(
    name: "deleteCostCategoryDefinition", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.DeleteCostCategoryDefinition",
    validator: validate_DeleteCostCategoryDefinition_599975, base: "/",
    url: url_DeleteCostCategoryDefinition_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCostCategoryDefinition_599989 = ref object of OpenApiRestCall_599368
proc url_DescribeCostCategoryDefinition_599991(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCostCategoryDefinition_599990(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN, rules, definition, and effective dates of a Cost Category that's defined in the account.</p> <p>You have the option to use <code>EffectiveOn</code> to return a Cost Category that is active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see a Cost Category that is effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
      "AWSInsightsIndexService.DescribeCostCategoryDefinition"))
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

proc call*(call_600001: Call_DescribeCostCategoryDefinition_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN, rules, definition, and effective dates of a Cost Category that's defined in the account.</p> <p>You have the option to use <code>EffectiveOn</code> to return a Cost Category that is active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see a Cost Category that is effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_DescribeCostCategoryDefinition_599989; body: JsonNode): Recallable =
  ## describeCostCategoryDefinition
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN, rules, definition, and effective dates of a Cost Category that's defined in the account.</p> <p>You have the option to use <code>EffectiveOn</code> to return a Cost Category that is active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see a Cost Category that is effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var describeCostCategoryDefinition* = Call_DescribeCostCategoryDefinition_599989(
    name: "describeCostCategoryDefinition", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.DescribeCostCategoryDefinition",
    validator: validate_DescribeCostCategoryDefinition_599990, base: "/",
    url: url_DescribeCostCategoryDefinition_599991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCostAndUsage_600004 = ref object of OpenApiRestCall_599368
proc url_GetCostAndUsage_600006(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCostAndUsage_600005(path: JsonNode; query: JsonNode;
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
      "AWSInsightsIndexService.GetCostAndUsage"))
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

proc call*(call_600016: Call_GetCostAndUsage_600004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves cost and usage metrics for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_GetCostAndUsage_600004; body: JsonNode): Recallable =
  ## getCostAndUsage
  ## Retrieves cost and usage metrics for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts.
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var getCostAndUsage* = Call_GetCostAndUsage_600004(name: "getCostAndUsage",
    meth: HttpMethod.HttpPost, host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetCostAndUsage",
    validator: validate_GetCostAndUsage_600005, base: "/", url: url_GetCostAndUsage_600006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCostAndUsageWithResources_600019 = ref object of OpenApiRestCall_599368
proc url_GetCostAndUsageWithResources_600021(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCostAndUsageWithResources_600020(path: JsonNode; query: JsonNode;
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
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetCostAndUsageWithResources"))
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

proc call*(call_600031: Call_GetCostAndUsageWithResources_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves cost and usage metrics with resources for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts. This API is currently available for the Amazon Elastic Compute Cloud – Compute service only.</p> <note> <p>This is an opt-in only feature. You can enable this feature from the Cost Explorer Settings page. For information on how to access the Settings page, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-access.html">Controlling Access for Cost Explorer</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> </note>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_GetCostAndUsageWithResources_600019; body: JsonNode): Recallable =
  ## getCostAndUsageWithResources
  ## <p>Retrieves cost and usage metrics with resources for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="http://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Master accounts in an organization in AWS Organizations have access to all member accounts. This API is currently available for the Amazon Elastic Compute Cloud – Compute service only.</p> <note> <p>This is an opt-in only feature. You can enable this feature from the Cost Explorer Settings page. For information on how to access the Settings page, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-access.html">Controlling Access for Cost Explorer</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var getCostAndUsageWithResources* = Call_GetCostAndUsageWithResources_600019(
    name: "getCostAndUsageWithResources", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetCostAndUsageWithResources",
    validator: validate_GetCostAndUsageWithResources_600020, base: "/",
    url: url_GetCostAndUsageWithResources_600021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCostForecast_600034 = ref object of OpenApiRestCall_599368
proc url_GetCostForecast_600036(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCostForecast_600035(path: JsonNode; query: JsonNode;
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
      "AWSInsightsIndexService.GetCostForecast"))
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

proc call*(call_600046: Call_GetCostForecast_600034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will spend over the forecast time period that you select, based on your past costs. 
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_GetCostForecast_600034; body: JsonNode): Recallable =
  ## getCostForecast
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will spend over the forecast time period that you select, based on your past costs. 
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var getCostForecast* = Call_GetCostForecast_600034(name: "getCostForecast",
    meth: HttpMethod.HttpPost, host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetCostForecast",
    validator: validate_GetCostForecast_600035, base: "/", url: url_GetCostForecast_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDimensionValues_600049 = ref object of OpenApiRestCall_599368
proc url_GetDimensionValues_600051(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDimensionValues_600050(path: JsonNode; query: JsonNode;
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
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetDimensionValues"))
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

proc call*(call_600061: Call_GetDimensionValues_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all available filter values for a specified filter over a period of time. You can search the dimension values for an arbitrary string. 
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_GetDimensionValues_600049; body: JsonNode): Recallable =
  ## getDimensionValues
  ## Retrieves all available filter values for a specified filter over a period of time. You can search the dimension values for an arbitrary string. 
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var getDimensionValues* = Call_GetDimensionValues_600049(
    name: "getDimensionValues", meth: HttpMethod.HttpPost, host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetDimensionValues",
    validator: validate_GetDimensionValues_600050, base: "/",
    url: url_GetDimensionValues_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReservationCoverage_600064 = ref object of OpenApiRestCall_599368
proc url_GetReservationCoverage_600066(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetReservationCoverage_600065(path: JsonNode; query: JsonNode;
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
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetReservationCoverage"))
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

proc call*(call_600076: Call_GetReservationCoverage_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the reservation coverage for your account. This enables you to see how much of your Amazon Elastic Compute Cloud, Amazon ElastiCache, Amazon Relational Database Service, or Amazon Redshift usage is covered by a reservation. An organization's master account can see the coverage of the associated member accounts. For any time period, you can filter data about reservation usage by the following dimensions:</p> <ul> <li> <p>AZ</p> </li> <li> <p>CACHE_ENGINE</p> </li> <li> <p>DATABASE_ENGINE</p> </li> <li> <p>DEPLOYMENT_OPTION</p> </li> <li> <p>INSTANCE_TYPE</p> </li> <li> <p>LINKED_ACCOUNT</p> </li> <li> <p>OPERATING_SYSTEM</p> </li> <li> <p>PLATFORM</p> </li> <li> <p>REGION</p> </li> <li> <p>SERVICE</p> </li> <li> <p>TAG</p> </li> <li> <p>TENANCY</p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation. </p>
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_GetReservationCoverage_600064; body: JsonNode): Recallable =
  ## getReservationCoverage
  ## <p>Retrieves the reservation coverage for your account. This enables you to see how much of your Amazon Elastic Compute Cloud, Amazon ElastiCache, Amazon Relational Database Service, or Amazon Redshift usage is covered by a reservation. An organization's master account can see the coverage of the associated member accounts. For any time period, you can filter data about reservation usage by the following dimensions:</p> <ul> <li> <p>AZ</p> </li> <li> <p>CACHE_ENGINE</p> </li> <li> <p>DATABASE_ENGINE</p> </li> <li> <p>DEPLOYMENT_OPTION</p> </li> <li> <p>INSTANCE_TYPE</p> </li> <li> <p>LINKED_ACCOUNT</p> </li> <li> <p>OPERATING_SYSTEM</p> </li> <li> <p>PLATFORM</p> </li> <li> <p>REGION</p> </li> <li> <p>SERVICE</p> </li> <li> <p>TAG</p> </li> <li> <p>TENANCY</p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation. </p>
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var getReservationCoverage* = Call_GetReservationCoverage_600064(
    name: "getReservationCoverage", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetReservationCoverage",
    validator: validate_GetReservationCoverage_600065, base: "/",
    url: url_GetReservationCoverage_600066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReservationPurchaseRecommendation_600079 = ref object of OpenApiRestCall_599368
proc url_GetReservationPurchaseRecommendation_600081(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetReservationPurchaseRecommendation_600080(path: JsonNode;
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
      "AWSInsightsIndexService.GetReservationPurchaseRecommendation"))
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

proc call*(call_600091: Call_GetReservationPurchaseRecommendation_600079;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets recommendations for which reservations to purchase. These recommendations could help you reduce your costs. Reservations provide a discounted hourly rate (up to 75%) compared to On-Demand pricing.</p> <p>AWS generates your recommendations by identifying your On-Demand usage during a specific time period and collecting your usage into categories that are eligible for a reservation. After AWS has these categories, it simulates every combination of reservations in each category of usage to identify the best number of each type of RI to purchase to maximize your estimated savings. </p> <p>For example, AWS automatically aggregates your Amazon EC2 Linux, shared tenancy, and c4 family usage in the US West (Oregon) Region and recommends that you buy size-flexible regional reservations to apply to the c4 family usage. AWS recommends the smallest size instance in an instance family. This makes it easier to purchase a size-flexible RI. AWS also shows the equal number of normalized units so that you can purchase any instance size that you want. For this example, your RI recommendation would be for <code>c4.large</code> because that is the smallest size instance in the c4 instance family.</p>
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_GetReservationPurchaseRecommendation_600079;
          body: JsonNode): Recallable =
  ## getReservationPurchaseRecommendation
  ## <p>Gets recommendations for which reservations to purchase. These recommendations could help you reduce your costs. Reservations provide a discounted hourly rate (up to 75%) compared to On-Demand pricing.</p> <p>AWS generates your recommendations by identifying your On-Demand usage during a specific time period and collecting your usage into categories that are eligible for a reservation. After AWS has these categories, it simulates every combination of reservations in each category of usage to identify the best number of each type of RI to purchase to maximize your estimated savings. </p> <p>For example, AWS automatically aggregates your Amazon EC2 Linux, shared tenancy, and c4 family usage in the US West (Oregon) Region and recommends that you buy size-flexible regional reservations to apply to the c4 family usage. AWS recommends the smallest size instance in an instance family. This makes it easier to purchase a size-flexible RI. AWS also shows the equal number of normalized units so that you can purchase any instance size that you want. For this example, your RI recommendation would be for <code>c4.large</code> because that is the smallest size instance in the c4 instance family.</p>
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var getReservationPurchaseRecommendation* = Call_GetReservationPurchaseRecommendation_600079(
    name: "getReservationPurchaseRecommendation", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetReservationPurchaseRecommendation",
    validator: validate_GetReservationPurchaseRecommendation_600080, base: "/",
    url: url_GetReservationPurchaseRecommendation_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReservationUtilization_600094 = ref object of OpenApiRestCall_599368
proc url_GetReservationUtilization_600096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetReservationUtilization_600095(path: JsonNode; query: JsonNode;
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
      "AWSInsightsIndexService.GetReservationUtilization"))
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

proc call*(call_600106: Call_GetReservationUtilization_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the reservation utilization for your account. Master accounts in an organization have access to member accounts. You can filter data by dimensions in a time period. You can use <code>GetDimensionValues</code> to determine the possible dimension values. Currently, you can group only by <code>SUBSCRIPTION_ID</code>. 
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_GetReservationUtilization_600094; body: JsonNode): Recallable =
  ## getReservationUtilization
  ## Retrieves the reservation utilization for your account. Master accounts in an organization have access to member accounts. You can filter data by dimensions in a time period. You can use <code>GetDimensionValues</code> to determine the possible dimension values. Currently, you can group only by <code>SUBSCRIPTION_ID</code>. 
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var getReservationUtilization* = Call_GetReservationUtilization_600094(
    name: "getReservationUtilization", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetReservationUtilization",
    validator: validate_GetReservationUtilization_600095, base: "/",
    url: url_GetReservationUtilization_600096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRightsizingRecommendation_600109 = ref object of OpenApiRestCall_599368
proc url_GetRightsizingRecommendation_600111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRightsizingRecommendation_600110(path: JsonNode; query: JsonNode;
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
      "AWSInsightsIndexService.GetRightsizingRecommendation"))
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

proc call*(call_600121: Call_GetRightsizingRecommendation_600109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates recommendations that helps you save cost by identifying idle and underutilized Amazon EC2 instances.</p> <p>Recommendations are generated to either downsize or terminate instances, along with providing savings detail and metrics. For details on calculation and function, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-what-is.html">Optimizing Your Cost with Rightsizing Recommendations</a>.</p>
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_GetRightsizingRecommendation_600109; body: JsonNode): Recallable =
  ## getRightsizingRecommendation
  ## <p>Creates recommendations that helps you save cost by identifying idle and underutilized Amazon EC2 instances.</p> <p>Recommendations are generated to either downsize or terminate instances, along with providing savings detail and metrics. For details on calculation and function, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-what-is.html">Optimizing Your Cost with Rightsizing Recommendations</a>.</p>
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var getRightsizingRecommendation* = Call_GetRightsizingRecommendation_600109(
    name: "getRightsizingRecommendation", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetRightsizingRecommendation",
    validator: validate_GetRightsizingRecommendation_600110, base: "/",
    url: url_GetRightsizingRecommendation_600111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSavingsPlansCoverage_600124 = ref object of OpenApiRestCall_599368
proc url_GetSavingsPlansCoverage_600126(protocol: Scheme; host: string; base: string;
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

proc validate_GetSavingsPlansCoverage_600125(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the Savings Plans covered for your account. This enables you to see how much of your cost is covered by a Savings Plan. An organization’s master account can see the coverage of the associated member accounts. For any time period, you can filter data for Savings Plans usage with the following dimensions:</p> <ul> <li> <p> <code>LINKED_ACCOUNT</code> </p> </li> <li> <p> <code>REGION</code> </p> </li> <li> <p> <code>SERVICE</code> </p> </li> <li> <p> <code>INSTANCE_FAMILY</code> </p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600127 = query.getOrDefault("NextToken")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "NextToken", valid_600127
  var valid_600128 = query.getOrDefault("MaxResults")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "MaxResults", valid_600128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600129 = header.getOrDefault("X-Amz-Date")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Date", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Security-Token")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Security-Token", valid_600130
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600131 = header.getOrDefault("X-Amz-Target")
  valid_600131 = validateParameter(valid_600131, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetSavingsPlansCoverage"))
  if valid_600131 != nil:
    section.add "X-Amz-Target", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Content-Sha256", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Algorithm")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Algorithm", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Signature")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Signature", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-SignedHeaders", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Credential")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Credential", valid_600136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600138: Call_GetSavingsPlansCoverage_600124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the Savings Plans covered for your account. This enables you to see how much of your cost is covered by a Savings Plan. An organization’s master account can see the coverage of the associated member accounts. For any time period, you can filter data for Savings Plans usage with the following dimensions:</p> <ul> <li> <p> <code>LINKED_ACCOUNT</code> </p> </li> <li> <p> <code>REGION</code> </p> </li> <li> <p> <code>SERVICE</code> </p> </li> <li> <p> <code>INSTANCE_FAMILY</code> </p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation.</p>
  ## 
  let valid = call_600138.validator(path, query, header, formData, body)
  let scheme = call_600138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600138.url(scheme.get, call_600138.host, call_600138.base,
                         call_600138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600138, url, valid)

proc call*(call_600139: Call_GetSavingsPlansCoverage_600124; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getSavingsPlansCoverage
  ## <p>Retrieves the Savings Plans covered for your account. This enables you to see how much of your cost is covered by a Savings Plan. An organization’s master account can see the coverage of the associated member accounts. For any time period, you can filter data for Savings Plans usage with the following dimensions:</p> <ul> <li> <p> <code>LINKED_ACCOUNT</code> </p> </li> <li> <p> <code>REGION</code> </p> </li> <li> <p> <code>SERVICE</code> </p> </li> <li> <p> <code>INSTANCE_FAMILY</code> </p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600140 = newJObject()
  var body_600141 = newJObject()
  add(query_600140, "NextToken", newJString(NextToken))
  if body != nil:
    body_600141 = body
  add(query_600140, "MaxResults", newJString(MaxResults))
  result = call_600139.call(nil, query_600140, nil, nil, body_600141)

var getSavingsPlansCoverage* = Call_GetSavingsPlansCoverage_600124(
    name: "getSavingsPlansCoverage", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansCoverage",
    validator: validate_GetSavingsPlansCoverage_600125, base: "/",
    url: url_GetSavingsPlansCoverage_600126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSavingsPlansPurchaseRecommendation_600143 = ref object of OpenApiRestCall_599368
proc url_GetSavingsPlansPurchaseRecommendation_600145(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSavingsPlansPurchaseRecommendation_600144(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600146 = header.getOrDefault("X-Amz-Date")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Date", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Security-Token")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Security-Token", valid_600147
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600148 = header.getOrDefault("X-Amz-Target")
  valid_600148 = validateParameter(valid_600148, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation"))
  if valid_600148 != nil:
    section.add "X-Amz-Target", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Content-Sha256", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Algorithm")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Algorithm", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Signature")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Signature", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-SignedHeaders", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Credential")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Credential", valid_600153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600155: Call_GetSavingsPlansPurchaseRecommendation_600143;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves your request parameters, Savings Plan Recommendations Summary and Details.
  ## 
  let valid = call_600155.validator(path, query, header, formData, body)
  let scheme = call_600155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600155.url(scheme.get, call_600155.host, call_600155.base,
                         call_600155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600155, url, valid)

proc call*(call_600156: Call_GetSavingsPlansPurchaseRecommendation_600143;
          body: JsonNode): Recallable =
  ## getSavingsPlansPurchaseRecommendation
  ## Retrieves your request parameters, Savings Plan Recommendations Summary and Details.
  ##   body: JObject (required)
  var body_600157 = newJObject()
  if body != nil:
    body_600157 = body
  result = call_600156.call(nil, nil, nil, nil, body_600157)

var getSavingsPlansPurchaseRecommendation* = Call_GetSavingsPlansPurchaseRecommendation_600143(
    name: "getSavingsPlansPurchaseRecommendation", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation",
    validator: validate_GetSavingsPlansPurchaseRecommendation_600144, base: "/",
    url: url_GetSavingsPlansPurchaseRecommendation_600145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSavingsPlansUtilization_600158 = ref object of OpenApiRestCall_599368
proc url_GetSavingsPlansUtilization_600160(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSavingsPlansUtilization_600159(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600161 = header.getOrDefault("X-Amz-Date")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Date", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Security-Token")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Security-Token", valid_600162
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600163 = header.getOrDefault("X-Amz-Target")
  valid_600163 = validateParameter(valid_600163, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetSavingsPlansUtilization"))
  if valid_600163 != nil:
    section.add "X-Amz-Target", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Content-Sha256", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Algorithm")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Algorithm", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-Signature")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Signature", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-SignedHeaders", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Credential")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Credential", valid_600168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600170: Call_GetSavingsPlansUtilization_600158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the Savings Plans utilization for your account across date ranges with daily or monthly granularity. Master accounts in an organization have access to member accounts. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p>You cannot group by any dimension values for <code>GetSavingsPlansUtilization</code>.</p> </note>
  ## 
  let valid = call_600170.validator(path, query, header, formData, body)
  let scheme = call_600170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600170.url(scheme.get, call_600170.host, call_600170.base,
                         call_600170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600170, url, valid)

proc call*(call_600171: Call_GetSavingsPlansUtilization_600158; body: JsonNode): Recallable =
  ## getSavingsPlansUtilization
  ## <p>Retrieves the Savings Plans utilization for your account across date ranges with daily or monthly granularity. Master accounts in an organization have access to member accounts. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p>You cannot group by any dimension values for <code>GetSavingsPlansUtilization</code>.</p> </note>
  ##   body: JObject (required)
  var body_600172 = newJObject()
  if body != nil:
    body_600172 = body
  result = call_600171.call(nil, nil, nil, nil, body_600172)

var getSavingsPlansUtilization* = Call_GetSavingsPlansUtilization_600158(
    name: "getSavingsPlansUtilization", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansUtilization",
    validator: validate_GetSavingsPlansUtilization_600159, base: "/",
    url: url_GetSavingsPlansUtilization_600160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSavingsPlansUtilizationDetails_600173 = ref object of OpenApiRestCall_599368
proc url_GetSavingsPlansUtilizationDetails_600175(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSavingsPlansUtilizationDetails_600174(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves attribute data along with aggregate utilization and savings data for a given time period. This doesn't support granular or grouped data (daily/monthly) in response. You can't retrieve data by dates in a single response similar to <code>GetSavingsPlanUtilization</code>, but you have the option to make multiple calls to <code>GetSavingsPlanUtilizationDetails</code> by providing individual dates. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p> <code>GetSavingsPlanUtilizationDetails</code> internally groups data by <code>SavingsPlansArn</code>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600176 = query.getOrDefault("NextToken")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "NextToken", valid_600176
  var valid_600177 = query.getOrDefault("MaxResults")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "MaxResults", valid_600177
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600178 = header.getOrDefault("X-Amz-Date")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Date", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Security-Token")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Security-Token", valid_600179
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600180 = header.getOrDefault("X-Amz-Target")
  valid_600180 = validateParameter(valid_600180, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetSavingsPlansUtilizationDetails"))
  if valid_600180 != nil:
    section.add "X-Amz-Target", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Content-Sha256", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Algorithm")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Algorithm", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Signature")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Signature", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-SignedHeaders", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Credential")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Credential", valid_600185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600187: Call_GetSavingsPlansUtilizationDetails_600173;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves attribute data along with aggregate utilization and savings data for a given time period. This doesn't support granular or grouped data (daily/monthly) in response. You can't retrieve data by dates in a single response similar to <code>GetSavingsPlanUtilization</code>, but you have the option to make multiple calls to <code>GetSavingsPlanUtilizationDetails</code> by providing individual dates. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p> <code>GetSavingsPlanUtilizationDetails</code> internally groups data by <code>SavingsPlansArn</code>.</p> </note>
  ## 
  let valid = call_600187.validator(path, query, header, formData, body)
  let scheme = call_600187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600187.url(scheme.get, call_600187.host, call_600187.base,
                         call_600187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600187, url, valid)

proc call*(call_600188: Call_GetSavingsPlansUtilizationDetails_600173;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getSavingsPlansUtilizationDetails
  ## <p>Retrieves attribute data along with aggregate utilization and savings data for a given time period. This doesn't support granular or grouped data (daily/monthly) in response. You can't retrieve data by dates in a single response similar to <code>GetSavingsPlanUtilization</code>, but you have the option to make multiple calls to <code>GetSavingsPlanUtilizationDetails</code> by providing individual dates. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p> <code>GetSavingsPlanUtilizationDetails</code> internally groups data by <code>SavingsPlansArn</code>.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600189 = newJObject()
  var body_600190 = newJObject()
  add(query_600189, "NextToken", newJString(NextToken))
  if body != nil:
    body_600190 = body
  add(query_600189, "MaxResults", newJString(MaxResults))
  result = call_600188.call(nil, query_600189, nil, nil, body_600190)

var getSavingsPlansUtilizationDetails* = Call_GetSavingsPlansUtilizationDetails_600173(
    name: "getSavingsPlansUtilizationDetails", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansUtilizationDetails",
    validator: validate_GetSavingsPlansUtilizationDetails_600174, base: "/",
    url: url_GetSavingsPlansUtilizationDetails_600175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_600191 = ref object of OpenApiRestCall_599368
proc url_GetTags_600193(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTags_600192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600194 = header.getOrDefault("X-Amz-Date")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Date", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Security-Token")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Security-Token", valid_600195
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600196 = header.getOrDefault("X-Amz-Target")
  valid_600196 = validateParameter(valid_600196, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetTags"))
  if valid_600196 != nil:
    section.add "X-Amz-Target", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Content-Sha256", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Algorithm")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Algorithm", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Signature")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Signature", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-SignedHeaders", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Credential")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Credential", valid_600201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600203: Call_GetTags_600191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Queries for available tag keys and tag values for a specified period. You can search the tag values for an arbitrary string. 
  ## 
  let valid = call_600203.validator(path, query, header, formData, body)
  let scheme = call_600203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600203.url(scheme.get, call_600203.host, call_600203.base,
                         call_600203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600203, url, valid)

proc call*(call_600204: Call_GetTags_600191; body: JsonNode): Recallable =
  ## getTags
  ## Queries for available tag keys and tag values for a specified period. You can search the tag values for an arbitrary string. 
  ##   body: JObject (required)
  var body_600205 = newJObject()
  if body != nil:
    body_600205 = body
  result = call_600204.call(nil, nil, nil, nil, body_600205)

var getTags* = Call_GetTags_600191(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.GetTags",
                                validator: validate_GetTags_600192, base: "/",
                                url: url_GetTags_600193,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsageForecast_600206 = ref object of OpenApiRestCall_599368
proc url_GetUsageForecast_600208(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUsageForecast_600207(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600209 = header.getOrDefault("X-Amz-Date")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Date", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Security-Token")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Security-Token", valid_600210
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600211 = header.getOrDefault("X-Amz-Target")
  valid_600211 = validateParameter(valid_600211, JString, required = true, default = newJString(
      "AWSInsightsIndexService.GetUsageForecast"))
  if valid_600211 != nil:
    section.add "X-Amz-Target", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Content-Sha256", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Algorithm")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Algorithm", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Signature")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Signature", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-SignedHeaders", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Credential")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Credential", valid_600216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600218: Call_GetUsageForecast_600206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will use over the forecast time period that you select, based on your past usage. 
  ## 
  let valid = call_600218.validator(path, query, header, formData, body)
  let scheme = call_600218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600218.url(scheme.get, call_600218.host, call_600218.base,
                         call_600218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600218, url, valid)

proc call*(call_600219: Call_GetUsageForecast_600206; body: JsonNode): Recallable =
  ## getUsageForecast
  ## Retrieves a forecast for how much Amazon Web Services predicts that you will use over the forecast time period that you select, based on your past usage. 
  ##   body: JObject (required)
  var body_600220 = newJObject()
  if body != nil:
    body_600220 = body
  result = call_600219.call(nil, nil, nil, nil, body_600220)

var getUsageForecast* = Call_GetUsageForecast_600206(name: "getUsageForecast",
    meth: HttpMethod.HttpPost, host: "ce.amazonaws.com",
    route: "/#X-Amz-Target=AWSInsightsIndexService.GetUsageForecast",
    validator: validate_GetUsageForecast_600207, base: "/",
    url: url_GetUsageForecast_600208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCostCategoryDefinitions_600221 = ref object of OpenApiRestCall_599368
proc url_ListCostCategoryDefinitions_600223(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCostCategoryDefinitions_600222(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN and effective dates of all Cost Categories defined in the account. You have the option to use <code>EffectiveOn</code> to return a list of Cost Categories that were active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see Cost Categories that are effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600224 = header.getOrDefault("X-Amz-Date")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Date", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Security-Token")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Security-Token", valid_600225
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600226 = header.getOrDefault("X-Amz-Target")
  valid_600226 = validateParameter(valid_600226, JString, required = true, default = newJString(
      "AWSInsightsIndexService.ListCostCategoryDefinitions"))
  if valid_600226 != nil:
    section.add "X-Amz-Target", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Content-Sha256", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Algorithm")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Algorithm", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Signature")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Signature", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-SignedHeaders", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Credential")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Credential", valid_600231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600233: Call_ListCostCategoryDefinitions_600221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN and effective dates of all Cost Categories defined in the account. You have the option to use <code>EffectiveOn</code> to return a list of Cost Categories that were active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see Cost Categories that are effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ## 
  let valid = call_600233.validator(path, query, header, formData, body)
  let scheme = call_600233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600233.url(scheme.get, call_600233.host, call_600233.base,
                         call_600233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600233, url, valid)

proc call*(call_600234: Call_ListCostCategoryDefinitions_600221; body: JsonNode): Recallable =
  ## listCostCategoryDefinitions
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Returns the name, ARN and effective dates of all Cost Categories defined in the account. You have the option to use <code>EffectiveOn</code> to return a list of Cost Categories that were active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see Cost Categories that are effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
  ##   body: JObject (required)
  var body_600235 = newJObject()
  if body != nil:
    body_600235 = body
  result = call_600234.call(nil, nil, nil, nil, body_600235)

var listCostCategoryDefinitions* = Call_ListCostCategoryDefinitions_600221(
    name: "listCostCategoryDefinitions", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.ListCostCategoryDefinitions",
    validator: validate_ListCostCategoryDefinitions_600222, base: "/",
    url: url_ListCostCategoryDefinitions_600223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCostCategoryDefinition_600236 = ref object of OpenApiRestCall_599368
proc url_UpdateCostCategoryDefinition_600238(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCostCategoryDefinition_600237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Updates an existing Cost Category. Changes made to the Cost Category rules will be used to categorize the current month’s expenses and future expenses. This won’t change categorization for the previous months.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600239 = header.getOrDefault("X-Amz-Date")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Date", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Security-Token")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Security-Token", valid_600240
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600241 = header.getOrDefault("X-Amz-Target")
  valid_600241 = validateParameter(valid_600241, JString, required = true, default = newJString(
      "AWSInsightsIndexService.UpdateCostCategoryDefinition"))
  if valid_600241 != nil:
    section.add "X-Amz-Target", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Content-Sha256", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Algorithm")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Algorithm", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Signature")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Signature", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-SignedHeaders", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Credential")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Credential", valid_600246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600248: Call_UpdateCostCategoryDefinition_600236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Updates an existing Cost Category. Changes made to the Cost Category rules will be used to categorize the current month’s expenses and future expenses. This won’t change categorization for the previous months.</p>
  ## 
  let valid = call_600248.validator(path, query, header, formData, body)
  let scheme = call_600248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600248.url(scheme.get, call_600248.host, call_600248.base,
                         call_600248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600248, url, valid)

proc call*(call_600249: Call_UpdateCostCategoryDefinition_600236; body: JsonNode): Recallable =
  ## updateCostCategoryDefinition
  ## <important> <p> <i> <b>Cost Category is in preview release for AWS Billing and Cost Management and is subject to change. Your use of Cost Categories is subject to the Beta Service Participation terms of the <a href="https://aws.amazon.com/service-terms/">AWS Service Terms</a> (Section 1.10).</b> </i> </p> </important> <p>Updates an existing Cost Category. Changes made to the Cost Category rules will be used to categorize the current month’s expenses and future expenses. This won’t change categorization for the previous months.</p>
  ##   body: JObject (required)
  var body_600250 = newJObject()
  if body != nil:
    body_600250 = body
  result = call_600249.call(nil, nil, nil, nil, body_600250)

var updateCostCategoryDefinition* = Call_UpdateCostCategoryDefinition_600236(
    name: "updateCostCategoryDefinition", meth: HttpMethod.HttpPost,
    host: "ce.amazonaws.com", route: "/#X-Amz-Target=AWSInsightsIndexService.UpdateCostCategoryDefinition",
    validator: validate_UpdateCostCategoryDefinition_600237, base: "/",
    url: url_UpdateCostCategoryDefinition_600238,
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
