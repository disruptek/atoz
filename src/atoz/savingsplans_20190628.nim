
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

## auto-generated via openapi macro
## title: AWS Savings Plans
## version: 2019-06-28
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Savings Plans are a pricing model that offer significant savings on AWS usage (for example, on Amazon EC2 instances). You commit to a consistent amount of usage, in USD per hour, for a term of 1 or 3 years, and receive a lower price for that usage. For more information, see the <a href="https://docs.aws.amazon.com/savingsplans/latest/userguide/">AWS Savings Plans User Guide</a>.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/savingsplans/
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
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616866): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "savingsplans.ap-northeast-1.amazonaws.com", "ap-southeast-1": "savingsplans.ap-southeast-1.amazonaws.com",
                           "us-west-2": "savingsplans.us-west-2.amazonaws.com",
                           "eu-west-2": "savingsplans.eu-west-2.amazonaws.com", "ap-northeast-3": "savingsplans.ap-northeast-3.amazonaws.com", "eu-central-1": "savingsplans.eu-central-1.amazonaws.com",
                           "us-east-2": "savingsplans.us-east-2.amazonaws.com",
                           "us-east-1": "savingsplans.us-east-1.amazonaws.com", "cn-northwest-1": "savingsplans.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "savingsplans.ap-northeast-2.amazonaws.com", "ap-south-1": "savingsplans.ap-south-1.amazonaws.com", "eu-north-1": "savingsplans.eu-north-1.amazonaws.com",
                           "us-west-1": "savingsplans.us-west-1.amazonaws.com", "us-gov-east-1": "savingsplans.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "savingsplans.eu-west-3.amazonaws.com", "cn-north-1": "savingsplans.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "savingsplans.sa-east-1.amazonaws.com",
                           "eu-west-1": "savingsplans.eu-west-1.amazonaws.com", "us-gov-west-1": "savingsplans.us-gov-west-1.amazonaws.com", "ap-southeast-2": "savingsplans.ap-southeast-2.amazonaws.com", "ca-central-1": "savingsplans.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "savingsplans.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "savingsplans.ap-southeast-1.amazonaws.com",
      "us-west-2": "savingsplans.us-west-2.amazonaws.com",
      "eu-west-2": "savingsplans.eu-west-2.amazonaws.com",
      "ap-northeast-3": "savingsplans.ap-northeast-3.amazonaws.com",
      "eu-central-1": "savingsplans.eu-central-1.amazonaws.com",
      "us-east-2": "savingsplans.us-east-2.amazonaws.com",
      "us-east-1": "savingsplans.us-east-1.amazonaws.com",
      "cn-northwest-1": "savingsplans.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "savingsplans.ap-northeast-2.amazonaws.com",
      "ap-south-1": "savingsplans.ap-south-1.amazonaws.com",
      "eu-north-1": "savingsplans.eu-north-1.amazonaws.com",
      "us-west-1": "savingsplans.us-west-1.amazonaws.com",
      "us-gov-east-1": "savingsplans.us-gov-east-1.amazonaws.com",
      "eu-west-3": "savingsplans.eu-west-3.amazonaws.com",
      "cn-north-1": "savingsplans.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "savingsplans.sa-east-1.amazonaws.com",
      "eu-west-1": "savingsplans.eu-west-1.amazonaws.com",
      "us-gov-west-1": "savingsplans.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "savingsplans.ap-southeast-2.amazonaws.com",
      "ca-central-1": "savingsplans.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "savingsplans"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateSavingsPlan_617205 = ref object of OpenApiRestCall_616866
proc url_CreateSavingsPlan_617207(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSavingsPlan_617206(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## Creates a Savings Plan.
  ## 
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617319 = header.getOrDefault("X-Amz-Date")
  valid_617319 = validateParameter(valid_617319, JString, required = false,
                                 default = nil)
  if valid_617319 != nil:
    section.add "X-Amz-Date", valid_617319
  var valid_617320 = header.getOrDefault("X-Amz-Security-Token")
  valid_617320 = validateParameter(valid_617320, JString, required = false,
                                 default = nil)
  if valid_617320 != nil:
    section.add "X-Amz-Security-Token", valid_617320
  var valid_617321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "X-Amz-Content-Sha256", valid_617321
  var valid_617322 = header.getOrDefault("X-Amz-Algorithm")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "X-Amz-Algorithm", valid_617322
  var valid_617323 = header.getOrDefault("X-Amz-Signature")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Signature", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-SignedHeaders", valid_617324
  var valid_617325 = header.getOrDefault("X-Amz-Credential")
  valid_617325 = validateParameter(valid_617325, JString, required = false,
                                 default = nil)
  if valid_617325 != nil:
    section.add "X-Amz-Credential", valid_617325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617350: Call_CreateSavingsPlan_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Savings Plan.
  ## 
  let valid = call_617350.validator(path, query, header, formData, body, _)
  let scheme = call_617350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617350.url(scheme.get, call_617350.host, call_617350.base,
                         call_617350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617350, url, valid, _)

proc call*(call_617421: Call_CreateSavingsPlan_617205; body: JsonNode): Recallable =
  ## createSavingsPlan
  ## Creates a Savings Plan.
  ##   body: JObject (required)
  var body_617422 = newJObject()
  if body != nil:
    body_617422 = body
  result = call_617421.call(nil, nil, nil, nil, body_617422)

var createSavingsPlan* = Call_CreateSavingsPlan_617205(name: "createSavingsPlan",
    meth: HttpMethod.HttpPost, host: "savingsplans.amazonaws.com",
    route: "/CreateSavingsPlan", validator: validate_CreateSavingsPlan_617206,
    base: "/", url: url_CreateSavingsPlan_617207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSavingsPlanRates_617463 = ref object of OpenApiRestCall_616866
proc url_DescribeSavingsPlanRates_617465(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSavingsPlanRates_617464(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Describes the specified Savings Plans rates.
  ## 
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617466 = header.getOrDefault("X-Amz-Date")
  valid_617466 = validateParameter(valid_617466, JString, required = false,
                                 default = nil)
  if valid_617466 != nil:
    section.add "X-Amz-Date", valid_617466
  var valid_617467 = header.getOrDefault("X-Amz-Security-Token")
  valid_617467 = validateParameter(valid_617467, JString, required = false,
                                 default = nil)
  if valid_617467 != nil:
    section.add "X-Amz-Security-Token", valid_617467
  var valid_617468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617468 = validateParameter(valid_617468, JString, required = false,
                                 default = nil)
  if valid_617468 != nil:
    section.add "X-Amz-Content-Sha256", valid_617468
  var valid_617469 = header.getOrDefault("X-Amz-Algorithm")
  valid_617469 = validateParameter(valid_617469, JString, required = false,
                                 default = nil)
  if valid_617469 != nil:
    section.add "X-Amz-Algorithm", valid_617469
  var valid_617470 = header.getOrDefault("X-Amz-Signature")
  valid_617470 = validateParameter(valid_617470, JString, required = false,
                                 default = nil)
  if valid_617470 != nil:
    section.add "X-Amz-Signature", valid_617470
  var valid_617471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617471 = validateParameter(valid_617471, JString, required = false,
                                 default = nil)
  if valid_617471 != nil:
    section.add "X-Amz-SignedHeaders", valid_617471
  var valid_617472 = header.getOrDefault("X-Amz-Credential")
  valid_617472 = validateParameter(valid_617472, JString, required = false,
                                 default = nil)
  if valid_617472 != nil:
    section.add "X-Amz-Credential", valid_617472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617474: Call_DescribeSavingsPlanRates_617463; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified Savings Plans rates.
  ## 
  let valid = call_617474.validator(path, query, header, formData, body, _)
  let scheme = call_617474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617474.url(scheme.get, call_617474.host, call_617474.base,
                         call_617474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617474, url, valid, _)

proc call*(call_617475: Call_DescribeSavingsPlanRates_617463; body: JsonNode): Recallable =
  ## describeSavingsPlanRates
  ## Describes the specified Savings Plans rates.
  ##   body: JObject (required)
  var body_617476 = newJObject()
  if body != nil:
    body_617476 = body
  result = call_617475.call(nil, nil, nil, nil, body_617476)

var describeSavingsPlanRates* = Call_DescribeSavingsPlanRates_617463(
    name: "describeSavingsPlanRates", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com", route: "/DescribeSavingsPlanRates",
    validator: validate_DescribeSavingsPlanRates_617464, base: "/",
    url: url_DescribeSavingsPlanRates_617465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSavingsPlans_617477 = ref object of OpenApiRestCall_616866
proc url_DescribeSavingsPlans_617479(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSavingsPlans_617478(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Describes the specified Savings Plans.
  ## 
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617480 = header.getOrDefault("X-Amz-Date")
  valid_617480 = validateParameter(valid_617480, JString, required = false,
                                 default = nil)
  if valid_617480 != nil:
    section.add "X-Amz-Date", valid_617480
  var valid_617481 = header.getOrDefault("X-Amz-Security-Token")
  valid_617481 = validateParameter(valid_617481, JString, required = false,
                                 default = nil)
  if valid_617481 != nil:
    section.add "X-Amz-Security-Token", valid_617481
  var valid_617482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617482 = validateParameter(valid_617482, JString, required = false,
                                 default = nil)
  if valid_617482 != nil:
    section.add "X-Amz-Content-Sha256", valid_617482
  var valid_617483 = header.getOrDefault("X-Amz-Algorithm")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "X-Amz-Algorithm", valid_617483
  var valid_617484 = header.getOrDefault("X-Amz-Signature")
  valid_617484 = validateParameter(valid_617484, JString, required = false,
                                 default = nil)
  if valid_617484 != nil:
    section.add "X-Amz-Signature", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-SignedHeaders", valid_617485
  var valid_617486 = header.getOrDefault("X-Amz-Credential")
  valid_617486 = validateParameter(valid_617486, JString, required = false,
                                 default = nil)
  if valid_617486 != nil:
    section.add "X-Amz-Credential", valid_617486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617488: Call_DescribeSavingsPlans_617477; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified Savings Plans.
  ## 
  let valid = call_617488.validator(path, query, header, formData, body, _)
  let scheme = call_617488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617488.url(scheme.get, call_617488.host, call_617488.base,
                         call_617488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617488, url, valid, _)

proc call*(call_617489: Call_DescribeSavingsPlans_617477; body: JsonNode): Recallable =
  ## describeSavingsPlans
  ## Describes the specified Savings Plans.
  ##   body: JObject (required)
  var body_617490 = newJObject()
  if body != nil:
    body_617490 = body
  result = call_617489.call(nil, nil, nil, nil, body_617490)

var describeSavingsPlans* = Call_DescribeSavingsPlans_617477(
    name: "describeSavingsPlans", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com", route: "/DescribeSavingsPlans",
    validator: validate_DescribeSavingsPlans_617478, base: "/",
    url: url_DescribeSavingsPlans_617479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSavingsPlansOfferingRates_617491 = ref object of OpenApiRestCall_616866
proc url_DescribeSavingsPlansOfferingRates_617493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSavingsPlansOfferingRates_617492(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Describes the specified Savings Plans offering rates.
  ## 
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
  var valid_617500 = header.getOrDefault("X-Amz-Credential")
  valid_617500 = validateParameter(valid_617500, JString, required = false,
                                 default = nil)
  if valid_617500 != nil:
    section.add "X-Amz-Credential", valid_617500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617502: Call_DescribeSavingsPlansOfferingRates_617491;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified Savings Plans offering rates.
  ## 
  let valid = call_617502.validator(path, query, header, formData, body, _)
  let scheme = call_617502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617502.url(scheme.get, call_617502.host, call_617502.base,
                         call_617502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617502, url, valid, _)

proc call*(call_617503: Call_DescribeSavingsPlansOfferingRates_617491;
          body: JsonNode): Recallable =
  ## describeSavingsPlansOfferingRates
  ## Describes the specified Savings Plans offering rates.
  ##   body: JObject (required)
  var body_617504 = newJObject()
  if body != nil:
    body_617504 = body
  result = call_617503.call(nil, nil, nil, nil, body_617504)

var describeSavingsPlansOfferingRates* = Call_DescribeSavingsPlansOfferingRates_617491(
    name: "describeSavingsPlansOfferingRates", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com",
    route: "/DescribeSavingsPlansOfferingRates",
    validator: validate_DescribeSavingsPlansOfferingRates_617492, base: "/",
    url: url_DescribeSavingsPlansOfferingRates_617493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSavingsPlansOfferings_617505 = ref object of OpenApiRestCall_616866
proc url_DescribeSavingsPlansOfferings_617507(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSavingsPlansOfferings_617506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Describes the specified Savings Plans offerings.
  ## 
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617508 = header.getOrDefault("X-Amz-Date")
  valid_617508 = validateParameter(valid_617508, JString, required = false,
                                 default = nil)
  if valid_617508 != nil:
    section.add "X-Amz-Date", valid_617508
  var valid_617509 = header.getOrDefault("X-Amz-Security-Token")
  valid_617509 = validateParameter(valid_617509, JString, required = false,
                                 default = nil)
  if valid_617509 != nil:
    section.add "X-Amz-Security-Token", valid_617509
  var valid_617510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617510 = validateParameter(valid_617510, JString, required = false,
                                 default = nil)
  if valid_617510 != nil:
    section.add "X-Amz-Content-Sha256", valid_617510
  var valid_617511 = header.getOrDefault("X-Amz-Algorithm")
  valid_617511 = validateParameter(valid_617511, JString, required = false,
                                 default = nil)
  if valid_617511 != nil:
    section.add "X-Amz-Algorithm", valid_617511
  var valid_617512 = header.getOrDefault("X-Amz-Signature")
  valid_617512 = validateParameter(valid_617512, JString, required = false,
                                 default = nil)
  if valid_617512 != nil:
    section.add "X-Amz-Signature", valid_617512
  var valid_617513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617513 = validateParameter(valid_617513, JString, required = false,
                                 default = nil)
  if valid_617513 != nil:
    section.add "X-Amz-SignedHeaders", valid_617513
  var valid_617514 = header.getOrDefault("X-Amz-Credential")
  valid_617514 = validateParameter(valid_617514, JString, required = false,
                                 default = nil)
  if valid_617514 != nil:
    section.add "X-Amz-Credential", valid_617514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617516: Call_DescribeSavingsPlansOfferings_617505;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified Savings Plans offerings.
  ## 
  let valid = call_617516.validator(path, query, header, formData, body, _)
  let scheme = call_617516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617516.url(scheme.get, call_617516.host, call_617516.base,
                         call_617516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617516, url, valid, _)

proc call*(call_617517: Call_DescribeSavingsPlansOfferings_617505; body: JsonNode): Recallable =
  ## describeSavingsPlansOfferings
  ## Describes the specified Savings Plans offerings.
  ##   body: JObject (required)
  var body_617518 = newJObject()
  if body != nil:
    body_617518 = body
  result = call_617517.call(nil, nil, nil, nil, body_617518)

var describeSavingsPlansOfferings* = Call_DescribeSavingsPlansOfferings_617505(
    name: "describeSavingsPlansOfferings", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com", route: "/DescribeSavingsPlansOfferings",
    validator: validate_DescribeSavingsPlansOfferings_617506, base: "/",
    url: url_DescribeSavingsPlansOfferings_617507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_617519 = ref object of OpenApiRestCall_616866
proc url_ListTagsForResource_617521(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_617520(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## Lists the tags for the specified resource.
  ## 
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617522 = header.getOrDefault("X-Amz-Date")
  valid_617522 = validateParameter(valid_617522, JString, required = false,
                                 default = nil)
  if valid_617522 != nil:
    section.add "X-Amz-Date", valid_617522
  var valid_617523 = header.getOrDefault("X-Amz-Security-Token")
  valid_617523 = validateParameter(valid_617523, JString, required = false,
                                 default = nil)
  if valid_617523 != nil:
    section.add "X-Amz-Security-Token", valid_617523
  var valid_617524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617524 = validateParameter(valid_617524, JString, required = false,
                                 default = nil)
  if valid_617524 != nil:
    section.add "X-Amz-Content-Sha256", valid_617524
  var valid_617525 = header.getOrDefault("X-Amz-Algorithm")
  valid_617525 = validateParameter(valid_617525, JString, required = false,
                                 default = nil)
  if valid_617525 != nil:
    section.add "X-Amz-Algorithm", valid_617525
  var valid_617526 = header.getOrDefault("X-Amz-Signature")
  valid_617526 = validateParameter(valid_617526, JString, required = false,
                                 default = nil)
  if valid_617526 != nil:
    section.add "X-Amz-Signature", valid_617526
  var valid_617527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617527 = validateParameter(valid_617527, JString, required = false,
                                 default = nil)
  if valid_617527 != nil:
    section.add "X-Amz-SignedHeaders", valid_617527
  var valid_617528 = header.getOrDefault("X-Amz-Credential")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Credential", valid_617528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617530: Call_ListTagsForResource_617519; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_617530.validator(path, query, header, formData, body, _)
  let scheme = call_617530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617530.url(scheme.get, call_617530.host, call_617530.base,
                         call_617530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617530, url, valid, _)

proc call*(call_617531: Call_ListTagsForResource_617519; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   body: JObject (required)
  var body_617532 = newJObject()
  if body != nil:
    body_617532 = body
  result = call_617531.call(nil, nil, nil, nil, body_617532)

var listTagsForResource* = Call_ListTagsForResource_617519(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com", route: "/ListTagsForResource",
    validator: validate_ListTagsForResource_617520, base: "/",
    url: url_ListTagsForResource_617521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617533 = ref object of OpenApiRestCall_616866
proc url_TagResource_617535(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_617534(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Adds the specified tags to the specified resource.
  ## 
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617536 = header.getOrDefault("X-Amz-Date")
  valid_617536 = validateParameter(valid_617536, JString, required = false,
                                 default = nil)
  if valid_617536 != nil:
    section.add "X-Amz-Date", valid_617536
  var valid_617537 = header.getOrDefault("X-Amz-Security-Token")
  valid_617537 = validateParameter(valid_617537, JString, required = false,
                                 default = nil)
  if valid_617537 != nil:
    section.add "X-Amz-Security-Token", valid_617537
  var valid_617538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617538 = validateParameter(valid_617538, JString, required = false,
                                 default = nil)
  if valid_617538 != nil:
    section.add "X-Amz-Content-Sha256", valid_617538
  var valid_617539 = header.getOrDefault("X-Amz-Algorithm")
  valid_617539 = validateParameter(valid_617539, JString, required = false,
                                 default = nil)
  if valid_617539 != nil:
    section.add "X-Amz-Algorithm", valid_617539
  var valid_617540 = header.getOrDefault("X-Amz-Signature")
  valid_617540 = validateParameter(valid_617540, JString, required = false,
                                 default = nil)
  if valid_617540 != nil:
    section.add "X-Amz-Signature", valid_617540
  var valid_617541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617541 = validateParameter(valid_617541, JString, required = false,
                                 default = nil)
  if valid_617541 != nil:
    section.add "X-Amz-SignedHeaders", valid_617541
  var valid_617542 = header.getOrDefault("X-Amz-Credential")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-Credential", valid_617542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617544: Call_TagResource_617533; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds the specified tags to the specified resource.
  ## 
  let valid = call_617544.validator(path, query, header, formData, body, _)
  let scheme = call_617544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617544.url(scheme.get, call_617544.host, call_617544.base,
                         call_617544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617544, url, valid, _)

proc call*(call_617545: Call_TagResource_617533; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource.
  ##   body: JObject (required)
  var body_617546 = newJObject()
  if body != nil:
    body_617546 = body
  result = call_617545.call(nil, nil, nil, nil, body_617546)

var tagResource* = Call_TagResource_617533(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "savingsplans.amazonaws.com",
                                        route: "/TagResource",
                                        validator: validate_TagResource_617534,
                                        base: "/", url: url_TagResource_617535,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617547 = ref object of OpenApiRestCall_616866
proc url_UntagResource_617549(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_617548(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Removes the specified tags from the specified resource.
  ## 
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617550 = header.getOrDefault("X-Amz-Date")
  valid_617550 = validateParameter(valid_617550, JString, required = false,
                                 default = nil)
  if valid_617550 != nil:
    section.add "X-Amz-Date", valid_617550
  var valid_617551 = header.getOrDefault("X-Amz-Security-Token")
  valid_617551 = validateParameter(valid_617551, JString, required = false,
                                 default = nil)
  if valid_617551 != nil:
    section.add "X-Amz-Security-Token", valid_617551
  var valid_617552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617552 = validateParameter(valid_617552, JString, required = false,
                                 default = nil)
  if valid_617552 != nil:
    section.add "X-Amz-Content-Sha256", valid_617552
  var valid_617553 = header.getOrDefault("X-Amz-Algorithm")
  valid_617553 = validateParameter(valid_617553, JString, required = false,
                                 default = nil)
  if valid_617553 != nil:
    section.add "X-Amz-Algorithm", valid_617553
  var valid_617554 = header.getOrDefault("X-Amz-Signature")
  valid_617554 = validateParameter(valid_617554, JString, required = false,
                                 default = nil)
  if valid_617554 != nil:
    section.add "X-Amz-Signature", valid_617554
  var valid_617555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617555 = validateParameter(valid_617555, JString, required = false,
                                 default = nil)
  if valid_617555 != nil:
    section.add "X-Amz-SignedHeaders", valid_617555
  var valid_617556 = header.getOrDefault("X-Amz-Credential")
  valid_617556 = validateParameter(valid_617556, JString, required = false,
                                 default = nil)
  if valid_617556 != nil:
    section.add "X-Amz-Credential", valid_617556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617558: Call_UntagResource_617547; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tags from the specified resource.
  ## 
  let valid = call_617558.validator(path, query, header, formData, body, _)
  let scheme = call_617558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617558.url(scheme.get, call_617558.host, call_617558.base,
                         call_617558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617558, url, valid, _)

proc call*(call_617559: Call_UntagResource_617547; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   body: JObject (required)
  var body_617560 = newJObject()
  if body != nil:
    body_617560 = body
  result = call_617559.call(nil, nil, nil, nil, body_617560)

var untagResource* = Call_UntagResource_617547(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "savingsplans.amazonaws.com",
    route: "/UntagResource", validator: validate_UntagResource_617548, base: "/",
    url: url_UntagResource_617549, schemes: {Scheme.Https, Scheme.Http})
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
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
