
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Health APIs and Notifications
## version: 2016-08-04
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Health</fullname> <p>The AWS Health API provides programmatic access to the AWS Health information that is presented in the <a href="https://phd.aws.amazon.com/phd/home#/">AWS Personal Health Dashboard</a>. You can get information about events that affect your AWS resources:</p> <ul> <li> <p> <a>DescribeEvents</a>: Summary information about events.</p> </li> <li> <p> <a>DescribeEventDetails</a>: Detailed information about one or more events.</p> </li> <li> <p> <a>DescribeAffectedEntities</a>: Information about AWS resources that are affected by one or more events.</p> </li> </ul> <p>In addition, these operations provide information about event types and summary counts of events or affected entities:</p> <ul> <li> <p> <a>DescribeEventTypes</a>: Information about the kinds of events that AWS Health tracks.</p> </li> <li> <p> <a>DescribeEventAggregates</a>: A count of the number of events that meet specified criteria.</p> </li> <li> <p> <a>DescribeEntityAggregates</a>: A count of the number of affected entities that meet specified criteria.</p> </li> </ul> <p>AWS Health integrates with AWS Organizations to provide a centralized view of AWS Health events across all accounts in your organization.</p> <ul> <li> <p> <a>DescribeEventsForOrganization</a>: Summary information about events across the organization.</p> </li> <li> <p> <a>DescribeAffectedAccountsForOrganization</a>: List of accounts in your organization impacted by an event.</p> </li> <li> <p> <a>DescribeEventDetailsForOrganization</a>: Detailed information about events in your organization.</p> </li> <li> <p> <a>DescribeAffectedEntitiesForOrganization</a>: Information about AWS resources in your organization that are affected by events.</p> </li> </ul> <p>You can use the following operations to enable or disable AWS Health from working with AWS Organizations.</p> <ul> <li> <p> <a>EnableHealthServiceAccessForOrganization</a>: Enables AWS Health to work with AWS Organizations.</p> </li> <li> <p> <a>DisableHealthServiceAccessForOrganization</a>: Disables AWS Health from working with AWS Organizations.</p> </li> <li> <p> <a>DescribeHealthServiceStatusForOrganization</a>: Status information about enabling or disabling AWS Health from working with AWS Organizations.</p> </li> </ul> <p>The Health API requires a Business or Enterprise support plan from <a href="http://aws.amazon.com/premiumsupport/">AWS Support</a>. Calling the Health API from an account that does not have a Business or Enterprise support plan causes a <code>SubscriptionRequiredException</code>.</p> <p>For authentication of requests, AWS Health uses the <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4 Signing Process</a>.</p> <p>See the <a href="https://docs.aws.amazon.com/health/latest/ug/what-is-aws-health.html">AWS Health User Guide</a> for information about how to use the API.</p> <p> <b>Service Endpoint</b> </p> <p>The HTTP endpoint for the AWS Health API is:</p> <ul> <li> <p>https://health.us-east-1.amazonaws.com </p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/health/
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "health"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeAffectedAccountsForOrganization_605927 = ref object of OpenApiRestCall_605589
proc url_DescribeAffectedAccountsForOrganization_605929(protocol: Scheme;
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

proc validate_DescribeAffectedAccountsForOrganization_605928(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606041 = query.getOrDefault("nextToken")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "nextToken", valid_606041
  var valid_606042 = query.getOrDefault("maxResults")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "maxResults", valid_606042
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
  var valid_606056 = header.getOrDefault("X-Amz-Target")
  valid_606056 = validateParameter(valid_606056, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedAccountsForOrganization"))
  if valid_606056 != nil:
    section.add "X-Amz-Target", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Signature")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Signature", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Content-Sha256", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Date")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Date", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Credential")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Credential", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Security-Token")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Security-Token", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Algorithm")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Algorithm", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-SignedHeaders", valid_606063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606087: Call_DescribeAffectedAccountsForOrganization_605927;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_606087.validator(path, query, header, formData, body)
  let scheme = call_606087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606087.url(scheme.get, call_606087.host, call_606087.base,
                         call_606087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606087, url, valid)

proc call*(call_606158: Call_DescribeAffectedAccountsForOrganization_605927;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeAffectedAccountsForOrganization
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606159 = newJObject()
  var body_606161 = newJObject()
  add(query_606159, "nextToken", newJString(nextToken))
  if body != nil:
    body_606161 = body
  add(query_606159, "maxResults", newJString(maxResults))
  result = call_606158.call(nil, query_606159, nil, nil, body_606161)

var describeAffectedAccountsForOrganization* = Call_DescribeAffectedAccountsForOrganization_605927(
    name: "describeAffectedAccountsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedAccountsForOrganization",
    validator: validate_DescribeAffectedAccountsForOrganization_605928, base: "/",
    url: url_DescribeAffectedAccountsForOrganization_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAffectedEntities_606200 = ref object of OpenApiRestCall_605589
proc url_DescribeAffectedEntities_606202(protocol: Scheme; host: string;
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

proc validate_DescribeAffectedEntities_606201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606203 = query.getOrDefault("nextToken")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "nextToken", valid_606203
  var valid_606204 = query.getOrDefault("maxResults")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "maxResults", valid_606204
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
  var valid_606205 = header.getOrDefault("X-Amz-Target")
  valid_606205 = validateParameter(valid_606205, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntities"))
  if valid_606205 != nil:
    section.add "X-Amz-Target", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Signature")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Signature", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Content-Sha256", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Date")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Date", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Credential")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Credential", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Security-Token")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Security-Token", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Algorithm")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Algorithm", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-SignedHeaders", valid_606212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606214: Call_DescribeAffectedEntities_606200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  let valid = call_606214.validator(path, query, header, formData, body)
  let scheme = call_606214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606214.url(scheme.get, call_606214.host, call_606214.base,
                         call_606214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606214, url, valid)

proc call*(call_606215: Call_DescribeAffectedEntities_606200; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeAffectedEntities
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606216 = newJObject()
  var body_606217 = newJObject()
  add(query_606216, "nextToken", newJString(nextToken))
  if body != nil:
    body_606217 = body
  add(query_606216, "maxResults", newJString(maxResults))
  result = call_606215.call(nil, query_606216, nil, nil, body_606217)

var describeAffectedEntities* = Call_DescribeAffectedEntities_606200(
    name: "describeAffectedEntities", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntities",
    validator: validate_DescribeAffectedEntities_606201, base: "/",
    url: url_DescribeAffectedEntities_606202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAffectedEntitiesForOrganization_606218 = ref object of OpenApiRestCall_605589
proc url_DescribeAffectedEntitiesForOrganization_606220(protocol: Scheme;
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

proc validate_DescribeAffectedEntitiesForOrganization_606219(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606221 = query.getOrDefault("nextToken")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "nextToken", valid_606221
  var valid_606222 = query.getOrDefault("maxResults")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "maxResults", valid_606222
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
  var valid_606223 = header.getOrDefault("X-Amz-Target")
  valid_606223 = validateParameter(valid_606223, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntitiesForOrganization"))
  if valid_606223 != nil:
    section.add "X-Amz-Target", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Signature")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Signature", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Content-Sha256", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Date")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Date", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Credential")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Credential", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Security-Token")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Security-Token", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Algorithm")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Algorithm", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-SignedHeaders", valid_606230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606232: Call_DescribeAffectedEntitiesForOrganization_606218;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ## 
  let valid = call_606232.validator(path, query, header, formData, body)
  let scheme = call_606232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606232.url(scheme.get, call_606232.host, call_606232.base,
                         call_606232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606232, url, valid)

proc call*(call_606233: Call_DescribeAffectedEntitiesForOrganization_606218;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeAffectedEntitiesForOrganization
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606234 = newJObject()
  var body_606235 = newJObject()
  add(query_606234, "nextToken", newJString(nextToken))
  if body != nil:
    body_606235 = body
  add(query_606234, "maxResults", newJString(maxResults))
  result = call_606233.call(nil, query_606234, nil, nil, body_606235)

var describeAffectedEntitiesForOrganization* = Call_DescribeAffectedEntitiesForOrganization_606218(
    name: "describeAffectedEntitiesForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntitiesForOrganization",
    validator: validate_DescribeAffectedEntitiesForOrganization_606219, base: "/",
    url: url_DescribeAffectedEntitiesForOrganization_606220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityAggregates_606236 = ref object of OpenApiRestCall_605589
proc url_DescribeEntityAggregates_606238(protocol: Scheme; host: string;
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

proc validate_DescribeEntityAggregates_606237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
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
  var valid_606239 = header.getOrDefault("X-Amz-Target")
  valid_606239 = validateParameter(valid_606239, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEntityAggregates"))
  if valid_606239 != nil:
    section.add "X-Amz-Target", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Signature")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Signature", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Content-Sha256", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Date")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Date", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Credential")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Credential", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Security-Token")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Security-Token", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Algorithm")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Algorithm", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-SignedHeaders", valid_606246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606248: Call_DescribeEntityAggregates_606236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ## 
  let valid = call_606248.validator(path, query, header, formData, body)
  let scheme = call_606248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606248.url(scheme.get, call_606248.host, call_606248.base,
                         call_606248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606248, url, valid)

proc call*(call_606249: Call_DescribeEntityAggregates_606236; body: JsonNode): Recallable =
  ## describeEntityAggregates
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ##   body: JObject (required)
  var body_606250 = newJObject()
  if body != nil:
    body_606250 = body
  result = call_606249.call(nil, nil, nil, nil, body_606250)

var describeEntityAggregates* = Call_DescribeEntityAggregates_606236(
    name: "describeEntityAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEntityAggregates",
    validator: validate_DescribeEntityAggregates_606237, base: "/",
    url: url_DescribeEntityAggregates_606238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventAggregates_606251 = ref object of OpenApiRestCall_605589
proc url_DescribeEventAggregates_606253(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventAggregates_606252(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606254 = query.getOrDefault("nextToken")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "nextToken", valid_606254
  var valid_606255 = query.getOrDefault("maxResults")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "maxResults", valid_606255
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
  var valid_606256 = header.getOrDefault("X-Amz-Target")
  valid_606256 = validateParameter(valid_606256, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventAggregates"))
  if valid_606256 != nil:
    section.add "X-Amz-Target", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Signature")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Signature", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Content-Sha256", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Date")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Date", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Credential")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Credential", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Security-Token")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Security-Token", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Algorithm")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Algorithm", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-SignedHeaders", valid_606263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606265: Call_DescribeEventAggregates_606251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  let valid = call_606265.validator(path, query, header, formData, body)
  let scheme = call_606265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606265.url(scheme.get, call_606265.host, call_606265.base,
                         call_606265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606265, url, valid)

proc call*(call_606266: Call_DescribeEventAggregates_606251; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEventAggregates
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606267 = newJObject()
  var body_606268 = newJObject()
  add(query_606267, "nextToken", newJString(nextToken))
  if body != nil:
    body_606268 = body
  add(query_606267, "maxResults", newJString(maxResults))
  result = call_606266.call(nil, query_606267, nil, nil, body_606268)

var describeEventAggregates* = Call_DescribeEventAggregates_606251(
    name: "describeEventAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventAggregates",
    validator: validate_DescribeEventAggregates_606252, base: "/",
    url: url_DescribeEventAggregates_606253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetails_606269 = ref object of OpenApiRestCall_605589
proc url_DescribeEventDetails_606271(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventDetails_606270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, and so on, as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
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
  var valid_606272 = header.getOrDefault("X-Amz-Target")
  valid_606272 = validateParameter(valid_606272, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetails"))
  if valid_606272 != nil:
    section.add "X-Amz-Target", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Signature")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Signature", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Content-Sha256", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Date")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Date", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Credential")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Credential", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Security-Token")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Security-Token", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Algorithm")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Algorithm", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-SignedHeaders", valid_606279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606281: Call_DescribeEventDetails_606269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, and so on, as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ## 
  let valid = call_606281.validator(path, query, header, formData, body)
  let scheme = call_606281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606281.url(scheme.get, call_606281.host, call_606281.base,
                         call_606281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606281, url, valid)

proc call*(call_606282: Call_DescribeEventDetails_606269; body: JsonNode): Recallable =
  ## describeEventDetails
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, and so on, as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ##   body: JObject (required)
  var body_606283 = newJObject()
  if body != nil:
    body_606283 = body
  result = call_606282.call(nil, nil, nil, nil, body_606283)

var describeEventDetails* = Call_DescribeEventDetails_606269(
    name: "describeEventDetails", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetails",
    validator: validate_DescribeEventDetails_606270, base: "/",
    url: url_DescribeEventDetails_606271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetailsForOrganization_606284 = ref object of OpenApiRestCall_605589
proc url_DescribeEventDetailsForOrganization_606286(protocol: Scheme; host: string;
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

proc validate_DescribeEventDetailsForOrganization_606285(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns detailed information about one or more specified events for one or more accounts in your organization. Information includes standard event data (Region, service, and so on, as returned by <a>DescribeEventsForOrganization</a>, a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntitiesForOrganization</a> operation.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
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
  var valid_606287 = header.getOrDefault("X-Amz-Target")
  valid_606287 = validateParameter(valid_606287, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetailsForOrganization"))
  if valid_606287 != nil:
    section.add "X-Amz-Target", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Signature")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Signature", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Content-Sha256", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Date")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Date", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Credential")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Credential", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Security-Token")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Security-Token", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Algorithm")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Algorithm", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-SignedHeaders", valid_606294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606296: Call_DescribeEventDetailsForOrganization_606284;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events for one or more accounts in your organization. Information includes standard event data (Region, service, and so on, as returned by <a>DescribeEventsForOrganization</a>, a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntitiesForOrganization</a> operation.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_606296.validator(path, query, header, formData, body)
  let scheme = call_606296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606296.url(scheme.get, call_606296.host, call_606296.base,
                         call_606296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606296, url, valid)

proc call*(call_606297: Call_DescribeEventDetailsForOrganization_606284;
          body: JsonNode): Recallable =
  ## describeEventDetailsForOrganization
  ## <p>Returns detailed information about one or more specified events for one or more accounts in your organization. Information includes standard event data (Region, service, and so on, as returned by <a>DescribeEventsForOrganization</a>, a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntitiesForOrganization</a> operation.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   body: JObject (required)
  var body_606298 = newJObject()
  if body != nil:
    body_606298 = body
  result = call_606297.call(nil, nil, nil, nil, body_606298)

var describeEventDetailsForOrganization* = Call_DescribeEventDetailsForOrganization_606284(
    name: "describeEventDetailsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetailsForOrganization",
    validator: validate_DescribeEventDetailsForOrganization_606285, base: "/",
    url: url_DescribeEventDetailsForOrganization_606286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTypes_606299 = ref object of OpenApiRestCall_605589
proc url_DescribeEventTypes_606301(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventTypes_606300(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606302 = query.getOrDefault("nextToken")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "nextToken", valid_606302
  var valid_606303 = query.getOrDefault("maxResults")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "maxResults", valid_606303
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
      "AWSHealth_20160804.DescribeEventTypes"))
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

proc call*(call_606313: Call_DescribeEventTypes_606299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_DescribeEventTypes_606299; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEventTypes
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606315 = newJObject()
  var body_606316 = newJObject()
  add(query_606315, "nextToken", newJString(nextToken))
  if body != nil:
    body_606316 = body
  add(query_606315, "maxResults", newJString(maxResults))
  result = call_606314.call(nil, query_606315, nil, nil, body_606316)

var describeEventTypes* = Call_DescribeEventTypes_606299(
    name: "describeEventTypes", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventTypes",
    validator: validate_DescribeEventTypes_606300, base: "/",
    url: url_DescribeEventTypes_606301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_606317 = ref object of OpenApiRestCall_605589
proc url_DescribeEvents_606319(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEvents_606318(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606320 = query.getOrDefault("nextToken")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "nextToken", valid_606320
  var valid_606321 = query.getOrDefault("maxResults")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "maxResults", valid_606321
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
  var valid_606322 = header.getOrDefault("X-Amz-Target")
  valid_606322 = validateParameter(valid_606322, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEvents"))
  if valid_606322 != nil:
    section.add "X-Amz-Target", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Signature")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Signature", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Content-Sha256", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Date")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Date", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Credential")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Credential", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Security-Token")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Security-Token", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Algorithm")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Algorithm", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-SignedHeaders", valid_606329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606331: Call_DescribeEvents_606317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  let valid = call_606331.validator(path, query, header, formData, body)
  let scheme = call_606331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606331.url(scheme.get, call_606331.host, call_606331.base,
                         call_606331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606331, url, valid)

proc call*(call_606332: Call_DescribeEvents_606317; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEvents
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606333 = newJObject()
  var body_606334 = newJObject()
  add(query_606333, "nextToken", newJString(nextToken))
  if body != nil:
    body_606334 = body
  add(query_606333, "maxResults", newJString(maxResults))
  result = call_606332.call(nil, query_606333, nil, nil, body_606334)

var describeEvents* = Call_DescribeEvents_606317(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEvents",
    validator: validate_DescribeEvents_606318, base: "/", url: url_DescribeEvents_606319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventsForOrganization_606335 = ref object of OpenApiRestCall_605589
proc url_DescribeEventsForOrganization_606337(protocol: Scheme; host: string;
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

proc validate_DescribeEventsForOrganization_606336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606338 = query.getOrDefault("nextToken")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "nextToken", valid_606338
  var valid_606339 = query.getOrDefault("maxResults")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "maxResults", valid_606339
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
  var valid_606340 = header.getOrDefault("X-Amz-Target")
  valid_606340 = validateParameter(valid_606340, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventsForOrganization"))
  if valid_606340 != nil:
    section.add "X-Amz-Target", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Signature")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Signature", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Content-Sha256", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Date")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Date", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Credential")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Credential", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Security-Token")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Security-Token", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Algorithm")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Algorithm", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-SignedHeaders", valid_606347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606349: Call_DescribeEventsForOrganization_606335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_606349.validator(path, query, header, formData, body)
  let scheme = call_606349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606349.url(scheme.get, call_606349.host, call_606349.base,
                         call_606349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606349, url, valid)

proc call*(call_606350: Call_DescribeEventsForOrganization_606335; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEventsForOrganization
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606351 = newJObject()
  var body_606352 = newJObject()
  add(query_606351, "nextToken", newJString(nextToken))
  if body != nil:
    body_606352 = body
  add(query_606351, "maxResults", newJString(maxResults))
  result = call_606350.call(nil, query_606351, nil, nil, body_606352)

var describeEventsForOrganization* = Call_DescribeEventsForOrganization_606335(
    name: "describeEventsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventsForOrganization",
    validator: validate_DescribeEventsForOrganization_606336, base: "/",
    url: url_DescribeEventsForOrganization_606337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHealthServiceStatusForOrganization_606353 = ref object of OpenApiRestCall_605589
proc url_DescribeHealthServiceStatusForOrganization_606355(protocol: Scheme;
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

proc validate_DescribeHealthServiceStatusForOrganization_606354(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation provides status information on enabling or disabling AWS Health to work with your organization. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
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
  var valid_606356 = header.getOrDefault("X-Amz-Target")
  valid_606356 = validateParameter(valid_606356, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeHealthServiceStatusForOrganization"))
  if valid_606356 != nil:
    section.add "X-Amz-Target", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Signature")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Signature", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Content-Sha256", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Date")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Date", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Credential")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Credential", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Security-Token")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Security-Token", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Algorithm")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Algorithm", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-SignedHeaders", valid_606363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606364: Call_DescribeHealthServiceStatusForOrganization_606353;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## This operation provides status information on enabling or disabling AWS Health to work with your organization. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_606364.validator(path, query, header, formData, body)
  let scheme = call_606364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606364.url(scheme.get, call_606364.host, call_606364.base,
                         call_606364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606364, url, valid)

proc call*(call_606365: Call_DescribeHealthServiceStatusForOrganization_606353): Recallable =
  ## describeHealthServiceStatusForOrganization
  ## This operation provides status information on enabling or disabling AWS Health to work with your organization. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_606365.call(nil, nil, nil, nil, nil)

var describeHealthServiceStatusForOrganization* = Call_DescribeHealthServiceStatusForOrganization_606353(
    name: "describeHealthServiceStatusForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeHealthServiceStatusForOrganization",
    validator: validate_DescribeHealthServiceStatusForOrganization_606354,
    base: "/", url: url_DescribeHealthServiceStatusForOrganization_606355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableHealthServiceAccessForOrganization_606366 = ref object of OpenApiRestCall_605589
proc url_DisableHealthServiceAccessForOrganization_606368(protocol: Scheme;
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

proc validate_DisableHealthServiceAccessForOrganization_606367(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Calling this operation disables Health from working with AWS Organizations. This does not remove the Service Linked Role (SLR) from the the master account in your organization. Use the IAM console, API, or AWS CLI to remove the SLR if desired. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
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
  var valid_606369 = header.getOrDefault("X-Amz-Target")
  valid_606369 = validateParameter(valid_606369, JString, required = true, default = newJString(
      "AWSHealth_20160804.DisableHealthServiceAccessForOrganization"))
  if valid_606369 != nil:
    section.add "X-Amz-Target", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Signature")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Signature", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Content-Sha256", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Date")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Date", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Credential")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Credential", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Security-Token")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Security-Token", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Algorithm")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Algorithm", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-SignedHeaders", valid_606376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606377: Call_DisableHealthServiceAccessForOrganization_606366;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Calling this operation disables Health from working with AWS Organizations. This does not remove the Service Linked Role (SLR) from the the master account in your organization. Use the IAM console, API, or AWS CLI to remove the SLR if desired. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_606377.validator(path, query, header, formData, body)
  let scheme = call_606377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606377.url(scheme.get, call_606377.host, call_606377.base,
                         call_606377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606377, url, valid)

proc call*(call_606378: Call_DisableHealthServiceAccessForOrganization_606366): Recallable =
  ## disableHealthServiceAccessForOrganization
  ## Calling this operation disables Health from working with AWS Organizations. This does not remove the Service Linked Role (SLR) from the the master account in your organization. Use the IAM console, API, or AWS CLI to remove the SLR if desired. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_606378.call(nil, nil, nil, nil, nil)

var disableHealthServiceAccessForOrganization* = Call_DisableHealthServiceAccessForOrganization_606366(
    name: "disableHealthServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DisableHealthServiceAccessForOrganization",
    validator: validate_DisableHealthServiceAccessForOrganization_606367,
    base: "/", url: url_DisableHealthServiceAccessForOrganization_606368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableHealthServiceAccessForOrganization_606379 = ref object of OpenApiRestCall_605589
proc url_EnableHealthServiceAccessForOrganization_606381(protocol: Scheme;
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

proc validate_EnableHealthServiceAccessForOrganization_606380(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Calling this operation enables AWS Health to work with AWS Organizations. This applies a Service Linked Role (SLR) to the master account in the organization. To learn more about the steps in this process, visit enabling service access for AWS Health in AWS Organizations. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
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
  var valid_606382 = header.getOrDefault("X-Amz-Target")
  valid_606382 = validateParameter(valid_606382, JString, required = true, default = newJString(
      "AWSHealth_20160804.EnableHealthServiceAccessForOrganization"))
  if valid_606382 != nil:
    section.add "X-Amz-Target", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Signature")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Signature", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Content-Sha256", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Date")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Date", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Credential")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Credential", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Security-Token")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Security-Token", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Algorithm")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Algorithm", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-SignedHeaders", valid_606389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606390: Call_EnableHealthServiceAccessForOrganization_606379;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Calling this operation enables AWS Health to work with AWS Organizations. This applies a Service Linked Role (SLR) to the master account in the organization. To learn more about the steps in this process, visit enabling service access for AWS Health in AWS Organizations. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_606390.validator(path, query, header, formData, body)
  let scheme = call_606390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606390.url(scheme.get, call_606390.host, call_606390.base,
                         call_606390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606390, url, valid)

proc call*(call_606391: Call_EnableHealthServiceAccessForOrganization_606379): Recallable =
  ## enableHealthServiceAccessForOrganization
  ## Calling this operation enables AWS Health to work with AWS Organizations. This applies a Service Linked Role (SLR) to the master account in the organization. To learn more about the steps in this process, visit enabling service access for AWS Health in AWS Organizations. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_606391.call(nil, nil, nil, nil, nil)

var enableHealthServiceAccessForOrganization* = Call_EnableHealthServiceAccessForOrganization_606379(
    name: "enableHealthServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.EnableHealthServiceAccessForOrganization",
    validator: validate_EnableHealthServiceAccessForOrganization_606380,
    base: "/", url: url_EnableHealthServiceAccessForOrganization_606381,
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
