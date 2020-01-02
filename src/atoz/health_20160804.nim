
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "health"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeAffectedAccountsForOrganization_599705 = ref object of OpenApiRestCall_599368
proc url_DescribeAffectedAccountsForOrganization_599707(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAffectedAccountsForOrganization_599706(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_599819 = query.getOrDefault("maxResults")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "maxResults", valid_599819
  var valid_599820 = query.getOrDefault("nextToken")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "nextToken", valid_599820
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599821 = header.getOrDefault("X-Amz-Date")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Date", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Security-Token")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Security-Token", valid_599822
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599836 = header.getOrDefault("X-Amz-Target")
  valid_599836 = validateParameter(valid_599836, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedAccountsForOrganization"))
  if valid_599836 != nil:
    section.add "X-Amz-Target", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Content-Sha256", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Algorithm")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Algorithm", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Signature")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Signature", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-SignedHeaders", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Credential")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Credential", valid_599841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599865: Call_DescribeAffectedAccountsForOrganization_599705;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_599865.validator(path, query, header, formData, body)
  let scheme = call_599865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599865.url(scheme.get, call_599865.host, call_599865.base,
                         call_599865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599865, url, valid)

proc call*(call_599936: Call_DescribeAffectedAccountsForOrganization_599705;
          body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeAffectedAccountsForOrganization
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599937 = newJObject()
  var body_599939 = newJObject()
  add(query_599937, "maxResults", newJString(maxResults))
  add(query_599937, "nextToken", newJString(nextToken))
  if body != nil:
    body_599939 = body
  result = call_599936.call(nil, query_599937, nil, nil, body_599939)

var describeAffectedAccountsForOrganization* = Call_DescribeAffectedAccountsForOrganization_599705(
    name: "describeAffectedAccountsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedAccountsForOrganization",
    validator: validate_DescribeAffectedAccountsForOrganization_599706, base: "/",
    url: url_DescribeAffectedAccountsForOrganization_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAffectedEntities_599978 = ref object of OpenApiRestCall_599368
proc url_DescribeAffectedEntities_599980(protocol: Scheme; host: string;
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

proc validate_DescribeAffectedEntities_599979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_599981 = query.getOrDefault("maxResults")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "maxResults", valid_599981
  var valid_599982 = query.getOrDefault("nextToken")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "nextToken", valid_599982
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599983 = header.getOrDefault("X-Amz-Date")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Date", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Security-Token")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Security-Token", valid_599984
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599985 = header.getOrDefault("X-Amz-Target")
  valid_599985 = validateParameter(valid_599985, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntities"))
  if valid_599985 != nil:
    section.add "X-Amz-Target", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Content-Sha256", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Algorithm")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Algorithm", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Signature")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Signature", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-SignedHeaders", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Credential")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Credential", valid_599990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599992: Call_DescribeAffectedEntities_599978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  let valid = call_599992.validator(path, query, header, formData, body)
  let scheme = call_599992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599992.url(scheme.get, call_599992.host, call_599992.base,
                         call_599992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599992, url, valid)

proc call*(call_599993: Call_DescribeAffectedEntities_599978; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeAffectedEntities
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599994 = newJObject()
  var body_599995 = newJObject()
  add(query_599994, "maxResults", newJString(maxResults))
  add(query_599994, "nextToken", newJString(nextToken))
  if body != nil:
    body_599995 = body
  result = call_599993.call(nil, query_599994, nil, nil, body_599995)

var describeAffectedEntities* = Call_DescribeAffectedEntities_599978(
    name: "describeAffectedEntities", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntities",
    validator: validate_DescribeAffectedEntities_599979, base: "/",
    url: url_DescribeAffectedEntities_599980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAffectedEntitiesForOrganization_599996 = ref object of OpenApiRestCall_599368
proc url_DescribeAffectedEntitiesForOrganization_599998(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAffectedEntitiesForOrganization_599997(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_599999 = query.getOrDefault("maxResults")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "maxResults", valid_599999
  var valid_600000 = query.getOrDefault("nextToken")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "nextToken", valid_600000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600001 = header.getOrDefault("X-Amz-Date")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Date", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Security-Token")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Security-Token", valid_600002
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600003 = header.getOrDefault("X-Amz-Target")
  valid_600003 = validateParameter(valid_600003, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntitiesForOrganization"))
  if valid_600003 != nil:
    section.add "X-Amz-Target", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Content-Sha256", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Algorithm")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Algorithm", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Signature")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Signature", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-SignedHeaders", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Credential")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Credential", valid_600008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600010: Call_DescribeAffectedEntitiesForOrganization_599996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ## 
  let valid = call_600010.validator(path, query, header, formData, body)
  let scheme = call_600010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600010.url(scheme.get, call_600010.host, call_600010.base,
                         call_600010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600010, url, valid)

proc call*(call_600011: Call_DescribeAffectedEntitiesForOrganization_599996;
          body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeAffectedEntitiesForOrganization
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600012 = newJObject()
  var body_600013 = newJObject()
  add(query_600012, "maxResults", newJString(maxResults))
  add(query_600012, "nextToken", newJString(nextToken))
  if body != nil:
    body_600013 = body
  result = call_600011.call(nil, query_600012, nil, nil, body_600013)

var describeAffectedEntitiesForOrganization* = Call_DescribeAffectedEntitiesForOrganization_599996(
    name: "describeAffectedEntitiesForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntitiesForOrganization",
    validator: validate_DescribeAffectedEntitiesForOrganization_599997, base: "/",
    url: url_DescribeAffectedEntitiesForOrganization_599998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityAggregates_600014 = ref object of OpenApiRestCall_599368
proc url_DescribeEntityAggregates_600016(protocol: Scheme; host: string;
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

proc validate_DescribeEntityAggregates_600015(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600017 = header.getOrDefault("X-Amz-Date")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Date", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Security-Token")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Security-Token", valid_600018
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600019 = header.getOrDefault("X-Amz-Target")
  valid_600019 = validateParameter(valid_600019, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEntityAggregates"))
  if valid_600019 != nil:
    section.add "X-Amz-Target", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Content-Sha256", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Algorithm")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Algorithm", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Signature")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Signature", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-SignedHeaders", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Credential")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Credential", valid_600024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600026: Call_DescribeEntityAggregates_600014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ## 
  let valid = call_600026.validator(path, query, header, formData, body)
  let scheme = call_600026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600026.url(scheme.get, call_600026.host, call_600026.base,
                         call_600026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600026, url, valid)

proc call*(call_600027: Call_DescribeEntityAggregates_600014; body: JsonNode): Recallable =
  ## describeEntityAggregates
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ##   body: JObject (required)
  var body_600028 = newJObject()
  if body != nil:
    body_600028 = body
  result = call_600027.call(nil, nil, nil, nil, body_600028)

var describeEntityAggregates* = Call_DescribeEntityAggregates_600014(
    name: "describeEntityAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEntityAggregates",
    validator: validate_DescribeEntityAggregates_600015, base: "/",
    url: url_DescribeEntityAggregates_600016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventAggregates_600029 = ref object of OpenApiRestCall_599368
proc url_DescribeEventAggregates_600031(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventAggregates_600030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600032 = query.getOrDefault("maxResults")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "maxResults", valid_600032
  var valid_600033 = query.getOrDefault("nextToken")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "nextToken", valid_600033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600034 = header.getOrDefault("X-Amz-Date")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Date", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Security-Token")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Security-Token", valid_600035
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600036 = header.getOrDefault("X-Amz-Target")
  valid_600036 = validateParameter(valid_600036, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventAggregates"))
  if valid_600036 != nil:
    section.add "X-Amz-Target", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Content-Sha256", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Algorithm")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Algorithm", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Signature")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Signature", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-SignedHeaders", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Credential")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Credential", valid_600041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600043: Call_DescribeEventAggregates_600029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  let valid = call_600043.validator(path, query, header, formData, body)
  let scheme = call_600043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600043.url(scheme.get, call_600043.host, call_600043.base,
                         call_600043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600043, url, valid)

proc call*(call_600044: Call_DescribeEventAggregates_600029; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEventAggregates
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600045 = newJObject()
  var body_600046 = newJObject()
  add(query_600045, "maxResults", newJString(maxResults))
  add(query_600045, "nextToken", newJString(nextToken))
  if body != nil:
    body_600046 = body
  result = call_600044.call(nil, query_600045, nil, nil, body_600046)

var describeEventAggregates* = Call_DescribeEventAggregates_600029(
    name: "describeEventAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventAggregates",
    validator: validate_DescribeEventAggregates_600030, base: "/",
    url: url_DescribeEventAggregates_600031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetails_600047 = ref object of OpenApiRestCall_599368
proc url_DescribeEventDetails_600049(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventDetails_600048(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600050 = header.getOrDefault("X-Amz-Date")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Date", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Security-Token")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Security-Token", valid_600051
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600052 = header.getOrDefault("X-Amz-Target")
  valid_600052 = validateParameter(valid_600052, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetails"))
  if valid_600052 != nil:
    section.add "X-Amz-Target", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Content-Sha256", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Algorithm")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Algorithm", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Signature")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Signature", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-SignedHeaders", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Credential")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Credential", valid_600057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600059: Call_DescribeEventDetails_600047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, and so on, as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ## 
  let valid = call_600059.validator(path, query, header, formData, body)
  let scheme = call_600059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600059.url(scheme.get, call_600059.host, call_600059.base,
                         call_600059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600059, url, valid)

proc call*(call_600060: Call_DescribeEventDetails_600047; body: JsonNode): Recallable =
  ## describeEventDetails
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, and so on, as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ##   body: JObject (required)
  var body_600061 = newJObject()
  if body != nil:
    body_600061 = body
  result = call_600060.call(nil, nil, nil, nil, body_600061)

var describeEventDetails* = Call_DescribeEventDetails_600047(
    name: "describeEventDetails", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetails",
    validator: validate_DescribeEventDetails_600048, base: "/",
    url: url_DescribeEventDetails_600049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetailsForOrganization_600062 = ref object of OpenApiRestCall_599368
proc url_DescribeEventDetailsForOrganization_600064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventDetailsForOrganization_600063(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600065 = header.getOrDefault("X-Amz-Date")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Date", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Security-Token")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Security-Token", valid_600066
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600067 = header.getOrDefault("X-Amz-Target")
  valid_600067 = validateParameter(valid_600067, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetailsForOrganization"))
  if valid_600067 != nil:
    section.add "X-Amz-Target", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Content-Sha256", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Algorithm")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Algorithm", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Signature")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Signature", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-SignedHeaders", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Credential")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Credential", valid_600072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600074: Call_DescribeEventDetailsForOrganization_600062;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events for one or more accounts in your organization. Information includes standard event data (Region, service, and so on, as returned by <a>DescribeEventsForOrganization</a>, a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntitiesForOrganization</a> operation.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_600074.validator(path, query, header, formData, body)
  let scheme = call_600074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600074.url(scheme.get, call_600074.host, call_600074.base,
                         call_600074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600074, url, valid)

proc call*(call_600075: Call_DescribeEventDetailsForOrganization_600062;
          body: JsonNode): Recallable =
  ## describeEventDetailsForOrganization
  ## <p>Returns detailed information about one or more specified events for one or more accounts in your organization. Information includes standard event data (Region, service, and so on, as returned by <a>DescribeEventsForOrganization</a>, a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntitiesForOrganization</a> operation.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   body: JObject (required)
  var body_600076 = newJObject()
  if body != nil:
    body_600076 = body
  result = call_600075.call(nil, nil, nil, nil, body_600076)

var describeEventDetailsForOrganization* = Call_DescribeEventDetailsForOrganization_600062(
    name: "describeEventDetailsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetailsForOrganization",
    validator: validate_DescribeEventDetailsForOrganization_600063, base: "/",
    url: url_DescribeEventDetailsForOrganization_600064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTypes_600077 = ref object of OpenApiRestCall_599368
proc url_DescribeEventTypes_600079(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventTypes_600078(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600080 = query.getOrDefault("maxResults")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "maxResults", valid_600080
  var valid_600081 = query.getOrDefault("nextToken")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "nextToken", valid_600081
  result.add "query", section
  ## parameters in `header` object:
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
      "AWSHealth_20160804.DescribeEventTypes"))
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

proc call*(call_600091: Call_DescribeEventTypes_600077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_DescribeEventTypes_600077; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEventTypes
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600093 = newJObject()
  var body_600094 = newJObject()
  add(query_600093, "maxResults", newJString(maxResults))
  add(query_600093, "nextToken", newJString(nextToken))
  if body != nil:
    body_600094 = body
  result = call_600092.call(nil, query_600093, nil, nil, body_600094)

var describeEventTypes* = Call_DescribeEventTypes_600077(
    name: "describeEventTypes", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventTypes",
    validator: validate_DescribeEventTypes_600078, base: "/",
    url: url_DescribeEventTypes_600079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_600095 = ref object of OpenApiRestCall_599368
proc url_DescribeEvents_600097(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvents_600096(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600098 = query.getOrDefault("maxResults")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "maxResults", valid_600098
  var valid_600099 = query.getOrDefault("nextToken")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "nextToken", valid_600099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600100 = header.getOrDefault("X-Amz-Date")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Date", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Security-Token")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Security-Token", valid_600101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600102 = header.getOrDefault("X-Amz-Target")
  valid_600102 = validateParameter(valid_600102, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEvents"))
  if valid_600102 != nil:
    section.add "X-Amz-Target", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Content-Sha256", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Algorithm")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Algorithm", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Signature")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Signature", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-SignedHeaders", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Credential")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Credential", valid_600107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600109: Call_DescribeEvents_600095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  let valid = call_600109.validator(path, query, header, formData, body)
  let scheme = call_600109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600109.url(scheme.get, call_600109.host, call_600109.base,
                         call_600109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600109, url, valid)

proc call*(call_600110: Call_DescribeEvents_600095; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEvents
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600111 = newJObject()
  var body_600112 = newJObject()
  add(query_600111, "maxResults", newJString(maxResults))
  add(query_600111, "nextToken", newJString(nextToken))
  if body != nil:
    body_600112 = body
  result = call_600110.call(nil, query_600111, nil, nil, body_600112)

var describeEvents* = Call_DescribeEvents_600095(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEvents",
    validator: validate_DescribeEvents_600096, base: "/", url: url_DescribeEvents_600097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventsForOrganization_600113 = ref object of OpenApiRestCall_599368
proc url_DescribeEventsForOrganization_600115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventsForOrganization_600114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600116 = query.getOrDefault("maxResults")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "maxResults", valid_600116
  var valid_600117 = query.getOrDefault("nextToken")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "nextToken", valid_600117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600118 = header.getOrDefault("X-Amz-Date")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Date", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Security-Token")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Security-Token", valid_600119
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600120 = header.getOrDefault("X-Amz-Target")
  valid_600120 = validateParameter(valid_600120, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventsForOrganization"))
  if valid_600120 != nil:
    section.add "X-Amz-Target", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Content-Sha256", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Algorithm")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Algorithm", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Signature")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Signature", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-SignedHeaders", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Credential")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Credential", valid_600125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600127: Call_DescribeEventsForOrganization_600113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_600127.validator(path, query, header, formData, body)
  let scheme = call_600127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600127.url(scheme.get, call_600127.host, call_600127.base,
                         call_600127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600127, url, valid)

proc call*(call_600128: Call_DescribeEventsForOrganization_600113; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEventsForOrganization
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600129 = newJObject()
  var body_600130 = newJObject()
  add(query_600129, "maxResults", newJString(maxResults))
  add(query_600129, "nextToken", newJString(nextToken))
  if body != nil:
    body_600130 = body
  result = call_600128.call(nil, query_600129, nil, nil, body_600130)

var describeEventsForOrganization* = Call_DescribeEventsForOrganization_600113(
    name: "describeEventsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventsForOrganization",
    validator: validate_DescribeEventsForOrganization_600114, base: "/",
    url: url_DescribeEventsForOrganization_600115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHealthServiceStatusForOrganization_600131 = ref object of OpenApiRestCall_599368
proc url_DescribeHealthServiceStatusForOrganization_600133(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHealthServiceStatusForOrganization_600132(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600134 = header.getOrDefault("X-Amz-Date")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Date", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Security-Token")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Security-Token", valid_600135
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600136 = header.getOrDefault("X-Amz-Target")
  valid_600136 = validateParameter(valid_600136, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeHealthServiceStatusForOrganization"))
  if valid_600136 != nil:
    section.add "X-Amz-Target", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Content-Sha256", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Algorithm")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Algorithm", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Signature")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Signature", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-SignedHeaders", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Credential")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Credential", valid_600141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600142: Call_DescribeHealthServiceStatusForOrganization_600131;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## This operation provides status information on enabling or disabling AWS Health to work with your organization. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_600142.validator(path, query, header, formData, body)
  let scheme = call_600142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600142.url(scheme.get, call_600142.host, call_600142.base,
                         call_600142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600142, url, valid)

proc call*(call_600143: Call_DescribeHealthServiceStatusForOrganization_600131): Recallable =
  ## describeHealthServiceStatusForOrganization
  ## This operation provides status information on enabling or disabling AWS Health to work with your organization. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_600143.call(nil, nil, nil, nil, nil)

var describeHealthServiceStatusForOrganization* = Call_DescribeHealthServiceStatusForOrganization_600131(
    name: "describeHealthServiceStatusForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeHealthServiceStatusForOrganization",
    validator: validate_DescribeHealthServiceStatusForOrganization_600132,
    base: "/", url: url_DescribeHealthServiceStatusForOrganization_600133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableHealthServiceAccessForOrganization_600144 = ref object of OpenApiRestCall_599368
proc url_DisableHealthServiceAccessForOrganization_600146(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableHealthServiceAccessForOrganization_600145(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600147 = header.getOrDefault("X-Amz-Date")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Date", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Security-Token")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Security-Token", valid_600148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600149 = header.getOrDefault("X-Amz-Target")
  valid_600149 = validateParameter(valid_600149, JString, required = true, default = newJString(
      "AWSHealth_20160804.DisableHealthServiceAccessForOrganization"))
  if valid_600149 != nil:
    section.add "X-Amz-Target", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Content-Sha256", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Algorithm")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Algorithm", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-Signature")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Signature", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-SignedHeaders", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Credential")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Credential", valid_600154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600155: Call_DisableHealthServiceAccessForOrganization_600144;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Calling this operation disables Health from working with AWS Organizations. This does not remove the Service Linked Role (SLR) from the the master account in your organization. Use the IAM console, API, or AWS CLI to remove the SLR if desired. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_600155.validator(path, query, header, formData, body)
  let scheme = call_600155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600155.url(scheme.get, call_600155.host, call_600155.base,
                         call_600155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600155, url, valid)

proc call*(call_600156: Call_DisableHealthServiceAccessForOrganization_600144): Recallable =
  ## disableHealthServiceAccessForOrganization
  ## Calling this operation disables Health from working with AWS Organizations. This does not remove the Service Linked Role (SLR) from the the master account in your organization. Use the IAM console, API, or AWS CLI to remove the SLR if desired. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_600156.call(nil, nil, nil, nil, nil)

var disableHealthServiceAccessForOrganization* = Call_DisableHealthServiceAccessForOrganization_600144(
    name: "disableHealthServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DisableHealthServiceAccessForOrganization",
    validator: validate_DisableHealthServiceAccessForOrganization_600145,
    base: "/", url: url_DisableHealthServiceAccessForOrganization_600146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableHealthServiceAccessForOrganization_600157 = ref object of OpenApiRestCall_599368
proc url_EnableHealthServiceAccessForOrganization_600159(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableHealthServiceAccessForOrganization_600158(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600160 = header.getOrDefault("X-Amz-Date")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Date", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Security-Token")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Security-Token", valid_600161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600162 = header.getOrDefault("X-Amz-Target")
  valid_600162 = validateParameter(valid_600162, JString, required = true, default = newJString(
      "AWSHealth_20160804.EnableHealthServiceAccessForOrganization"))
  if valid_600162 != nil:
    section.add "X-Amz-Target", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Content-Sha256", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Algorithm")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Algorithm", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Signature")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Signature", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-SignedHeaders", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Credential")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Credential", valid_600167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600168: Call_EnableHealthServiceAccessForOrganization_600157;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Calling this operation enables AWS Health to work with AWS Organizations. This applies a Service Linked Role (SLR) to the master account in the organization. To learn more about the steps in this process, visit enabling service access for AWS Health in AWS Organizations. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_600168.validator(path, query, header, formData, body)
  let scheme = call_600168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600168.url(scheme.get, call_600168.host, call_600168.base,
                         call_600168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600168, url, valid)

proc call*(call_600169: Call_EnableHealthServiceAccessForOrganization_600157): Recallable =
  ## enableHealthServiceAccessForOrganization
  ## Calling this operation enables AWS Health to work with AWS Organizations. This applies a Service Linked Role (SLR) to the master account in the organization. To learn more about the steps in this process, visit enabling service access for AWS Health in AWS Organizations. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_600169.call(nil, nil, nil, nil, nil)

var enableHealthServiceAccessForOrganization* = Call_EnableHealthServiceAccessForOrganization_600157(
    name: "enableHealthServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.EnableHealthServiceAccessForOrganization",
    validator: validate_EnableHealthServiceAccessForOrganization_600158,
    base: "/", url: url_EnableHealthServiceAccessForOrganization_600159,
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
