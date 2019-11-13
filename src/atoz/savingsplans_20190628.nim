
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "savingsplans.ap-northeast-1.amazonaws.com", "ap-southeast-1": "savingsplans.ap-southeast-1.amazonaws.com",
                           "us-west-2": "savingsplans.us-west-2.amazonaws.com",
                           "eu-west-2": "savingsplans.eu-west-2.amazonaws.com", "ap-northeast-3": "savingsplans.ap-northeast-3.amazonaws.com", "eu-central-1": "savingsplans.eu-central-1.amazonaws.com",
                           "us-east-2": "savingsplans.us-east-2.amazonaws.com",
                           "us-east-1": "savingsplans.us-east-1.amazonaws.com", "cn-northwest-1": "savingsplans.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "savingsplans.ap-south-1.amazonaws.com", "eu-north-1": "savingsplans.eu-north-1.amazonaws.com", "ap-northeast-2": "savingsplans.ap-northeast-2.amazonaws.com",
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
      "ap-south-1": "savingsplans.ap-south-1.amazonaws.com",
      "eu-north-1": "savingsplans.eu-north-1.amazonaws.com",
      "ap-northeast-2": "savingsplans.ap-northeast-2.amazonaws.com",
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateSavingsPlan_593727 = ref object of OpenApiRestCall_593389
proc url_CreateSavingsPlan_593729(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSavingsPlan_593728(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a Savings Plan.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593841 = header.getOrDefault("X-Amz-Signature")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-Signature", valid_593841
  var valid_593842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "X-Amz-Content-Sha256", valid_593842
  var valid_593843 = header.getOrDefault("X-Amz-Date")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-Date", valid_593843
  var valid_593844 = header.getOrDefault("X-Amz-Credential")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "X-Amz-Credential", valid_593844
  var valid_593845 = header.getOrDefault("X-Amz-Security-Token")
  valid_593845 = validateParameter(valid_593845, JString, required = false,
                                 default = nil)
  if valid_593845 != nil:
    section.add "X-Amz-Security-Token", valid_593845
  var valid_593846 = header.getOrDefault("X-Amz-Algorithm")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-Algorithm", valid_593846
  var valid_593847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "X-Amz-SignedHeaders", valid_593847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593871: Call_CreateSavingsPlan_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Savings Plan.
  ## 
  let valid = call_593871.validator(path, query, header, formData, body)
  let scheme = call_593871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593871.url(scheme.get, call_593871.host, call_593871.base,
                         call_593871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593871, url, valid)

proc call*(call_593942: Call_CreateSavingsPlan_593727; body: JsonNode): Recallable =
  ## createSavingsPlan
  ## Creates a Savings Plan.
  ##   body: JObject (required)
  var body_593943 = newJObject()
  if body != nil:
    body_593943 = body
  result = call_593942.call(nil, nil, nil, nil, body_593943)

var createSavingsPlan* = Call_CreateSavingsPlan_593727(name: "createSavingsPlan",
    meth: HttpMethod.HttpPost, host: "savingsplans.amazonaws.com",
    route: "/CreateSavingsPlan", validator: validate_CreateSavingsPlan_593728,
    base: "/", url: url_CreateSavingsPlan_593729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSavingsPlanRates_593982 = ref object of OpenApiRestCall_593389
proc url_DescribeSavingsPlanRates_593984(protocol: Scheme; host: string;
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

proc validate_DescribeSavingsPlanRates_593983(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified Savings Plans rates.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593985 = header.getOrDefault("X-Amz-Signature")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "X-Amz-Signature", valid_593985
  var valid_593986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593986 = validateParameter(valid_593986, JString, required = false,
                                 default = nil)
  if valid_593986 != nil:
    section.add "X-Amz-Content-Sha256", valid_593986
  var valid_593987 = header.getOrDefault("X-Amz-Date")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "X-Amz-Date", valid_593987
  var valid_593988 = header.getOrDefault("X-Amz-Credential")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "X-Amz-Credential", valid_593988
  var valid_593989 = header.getOrDefault("X-Amz-Security-Token")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "X-Amz-Security-Token", valid_593989
  var valid_593990 = header.getOrDefault("X-Amz-Algorithm")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "X-Amz-Algorithm", valid_593990
  var valid_593991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "X-Amz-SignedHeaders", valid_593991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593993: Call_DescribeSavingsPlanRates_593982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Savings Plans rates.
  ## 
  let valid = call_593993.validator(path, query, header, formData, body)
  let scheme = call_593993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593993.url(scheme.get, call_593993.host, call_593993.base,
                         call_593993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593993, url, valid)

proc call*(call_593994: Call_DescribeSavingsPlanRates_593982; body: JsonNode): Recallable =
  ## describeSavingsPlanRates
  ## Describes the specified Savings Plans rates.
  ##   body: JObject (required)
  var body_593995 = newJObject()
  if body != nil:
    body_593995 = body
  result = call_593994.call(nil, nil, nil, nil, body_593995)

var describeSavingsPlanRates* = Call_DescribeSavingsPlanRates_593982(
    name: "describeSavingsPlanRates", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com", route: "/DescribeSavingsPlanRates",
    validator: validate_DescribeSavingsPlanRates_593983, base: "/",
    url: url_DescribeSavingsPlanRates_593984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSavingsPlans_593996 = ref object of OpenApiRestCall_593389
proc url_DescribeSavingsPlans_593998(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSavingsPlans_593997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified Savings Plans.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593999 = header.getOrDefault("X-Amz-Signature")
  valid_593999 = validateParameter(valid_593999, JString, required = false,
                                 default = nil)
  if valid_593999 != nil:
    section.add "X-Amz-Signature", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Content-Sha256", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Date")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Date", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Credential")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Credential", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Security-Token")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Security-Token", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Algorithm")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Algorithm", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-SignedHeaders", valid_594005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594007: Call_DescribeSavingsPlans_593996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Savings Plans.
  ## 
  let valid = call_594007.validator(path, query, header, formData, body)
  let scheme = call_594007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594007.url(scheme.get, call_594007.host, call_594007.base,
                         call_594007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594007, url, valid)

proc call*(call_594008: Call_DescribeSavingsPlans_593996; body: JsonNode): Recallable =
  ## describeSavingsPlans
  ## Describes the specified Savings Plans.
  ##   body: JObject (required)
  var body_594009 = newJObject()
  if body != nil:
    body_594009 = body
  result = call_594008.call(nil, nil, nil, nil, body_594009)

var describeSavingsPlans* = Call_DescribeSavingsPlans_593996(
    name: "describeSavingsPlans", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com", route: "/DescribeSavingsPlans",
    validator: validate_DescribeSavingsPlans_593997, base: "/",
    url: url_DescribeSavingsPlans_593998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSavingsPlansOfferingRates_594010 = ref object of OpenApiRestCall_593389
proc url_DescribeSavingsPlansOfferingRates_594012(protocol: Scheme; host: string;
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

proc validate_DescribeSavingsPlansOfferingRates_594011(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified Savings Plans offering rates.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594013 = header.getOrDefault("X-Amz-Signature")
  valid_594013 = validateParameter(valid_594013, JString, required = false,
                                 default = nil)
  if valid_594013 != nil:
    section.add "X-Amz-Signature", valid_594013
  var valid_594014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594014 = validateParameter(valid_594014, JString, required = false,
                                 default = nil)
  if valid_594014 != nil:
    section.add "X-Amz-Content-Sha256", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Date")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Date", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-Credential")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Credential", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Security-Token")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Security-Token", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Algorithm")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Algorithm", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-SignedHeaders", valid_594019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594021: Call_DescribeSavingsPlansOfferingRates_594010;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the specified Savings Plans offering rates.
  ## 
  let valid = call_594021.validator(path, query, header, formData, body)
  let scheme = call_594021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594021.url(scheme.get, call_594021.host, call_594021.base,
                         call_594021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594021, url, valid)

proc call*(call_594022: Call_DescribeSavingsPlansOfferingRates_594010;
          body: JsonNode): Recallable =
  ## describeSavingsPlansOfferingRates
  ## Describes the specified Savings Plans offering rates.
  ##   body: JObject (required)
  var body_594023 = newJObject()
  if body != nil:
    body_594023 = body
  result = call_594022.call(nil, nil, nil, nil, body_594023)

var describeSavingsPlansOfferingRates* = Call_DescribeSavingsPlansOfferingRates_594010(
    name: "describeSavingsPlansOfferingRates", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com",
    route: "/DescribeSavingsPlansOfferingRates",
    validator: validate_DescribeSavingsPlansOfferingRates_594011, base: "/",
    url: url_DescribeSavingsPlansOfferingRates_594012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSavingsPlansOfferings_594024 = ref object of OpenApiRestCall_593389
proc url_DescribeSavingsPlansOfferings_594026(protocol: Scheme; host: string;
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

proc validate_DescribeSavingsPlansOfferings_594025(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified Savings Plans offerings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594027 = header.getOrDefault("X-Amz-Signature")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "X-Amz-Signature", valid_594027
  var valid_594028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594028 = validateParameter(valid_594028, JString, required = false,
                                 default = nil)
  if valid_594028 != nil:
    section.add "X-Amz-Content-Sha256", valid_594028
  var valid_594029 = header.getOrDefault("X-Amz-Date")
  valid_594029 = validateParameter(valid_594029, JString, required = false,
                                 default = nil)
  if valid_594029 != nil:
    section.add "X-Amz-Date", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Credential")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Credential", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Security-Token")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Security-Token", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Algorithm")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Algorithm", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-SignedHeaders", valid_594033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594035: Call_DescribeSavingsPlansOfferings_594024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Savings Plans offerings.
  ## 
  let valid = call_594035.validator(path, query, header, formData, body)
  let scheme = call_594035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594035.url(scheme.get, call_594035.host, call_594035.base,
                         call_594035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594035, url, valid)

proc call*(call_594036: Call_DescribeSavingsPlansOfferings_594024; body: JsonNode): Recallable =
  ## describeSavingsPlansOfferings
  ## Describes the specified Savings Plans offerings.
  ##   body: JObject (required)
  var body_594037 = newJObject()
  if body != nil:
    body_594037 = body
  result = call_594036.call(nil, nil, nil, nil, body_594037)

var describeSavingsPlansOfferings* = Call_DescribeSavingsPlansOfferings_594024(
    name: "describeSavingsPlansOfferings", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com", route: "/DescribeSavingsPlansOfferings",
    validator: validate_DescribeSavingsPlansOfferings_594025, base: "/",
    url: url_DescribeSavingsPlansOfferings_594026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594038 = ref object of OpenApiRestCall_593389
proc url_ListTagsForResource_594040(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_594039(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags for the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594041 = header.getOrDefault("X-Amz-Signature")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Signature", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-Content-Sha256", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Date")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Date", valid_594043
  var valid_594044 = header.getOrDefault("X-Amz-Credential")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-Credential", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Security-Token")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Security-Token", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Algorithm")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Algorithm", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-SignedHeaders", valid_594047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594049: Call_ListTagsForResource_594038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_594049.validator(path, query, header, formData, body)
  let scheme = call_594049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594049.url(scheme.get, call_594049.host, call_594049.base,
                         call_594049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594049, url, valid)

proc call*(call_594050: Call_ListTagsForResource_594038; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   body: JObject (required)
  var body_594051 = newJObject()
  if body != nil:
    body_594051 = body
  result = call_594050.call(nil, nil, nil, nil, body_594051)

var listTagsForResource* = Call_ListTagsForResource_594038(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "savingsplans.amazonaws.com", route: "/ListTagsForResource",
    validator: validate_ListTagsForResource_594039, base: "/",
    url: url_ListTagsForResource_594040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594052 = ref object of OpenApiRestCall_593389
proc url_TagResource_594054(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_594053(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified tags to the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594055 = header.getOrDefault("X-Amz-Signature")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Signature", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Content-Sha256", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Date")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Date", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Credential")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Credential", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Security-Token")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Security-Token", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Algorithm")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Algorithm", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-SignedHeaders", valid_594061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594063: Call_TagResource_594052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified resource.
  ## 
  let valid = call_594063.validator(path, query, header, formData, body)
  let scheme = call_594063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594063.url(scheme.get, call_594063.host, call_594063.base,
                         call_594063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594063, url, valid)

proc call*(call_594064: Call_TagResource_594052; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource.
  ##   body: JObject (required)
  var body_594065 = newJObject()
  if body != nil:
    body_594065 = body
  result = call_594064.call(nil, nil, nil, nil, body_594065)

var tagResource* = Call_TagResource_594052(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "savingsplans.amazonaws.com",
                                        route: "/TagResource",
                                        validator: validate_TagResource_594053,
                                        base: "/", url: url_TagResource_594054,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594066 = ref object of OpenApiRestCall_593389
proc url_UntagResource_594068(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_594067(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594069 = header.getOrDefault("X-Amz-Signature")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Signature", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Content-Sha256", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Date")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Date", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Credential")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Credential", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Security-Token")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Security-Token", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Algorithm")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Algorithm", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-SignedHeaders", valid_594075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594077: Call_UntagResource_594066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource.
  ## 
  let valid = call_594077.validator(path, query, header, formData, body)
  let scheme = call_594077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594077.url(scheme.get, call_594077.host, call_594077.base,
                         call_594077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594077, url, valid)

proc call*(call_594078: Call_UntagResource_594066; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   body: JObject (required)
  var body_594079 = newJObject()
  if body != nil:
    body_594079 = body
  result = call_594078.call(nil, nil, nil, nil, body_594079)

var untagResource* = Call_UntagResource_594066(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "savingsplans.amazonaws.com",
    route: "/UntagResource", validator: validate_UntagResource_594067, base: "/",
    url: url_UntagResource_594068, schemes: {Scheme.Https, Scheme.Http})
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
