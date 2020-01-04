
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_DescribeAffectedAccountsForOrganization_601727 = ref object of OpenApiRestCall_601389
proc url_DescribeAffectedAccountsForOrganization_601729(protocol: Scheme;
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

proc validate_DescribeAffectedAccountsForOrganization_601728(path: JsonNode;
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
  var valid_601841 = query.getOrDefault("nextToken")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "nextToken", valid_601841
  var valid_601842 = query.getOrDefault("maxResults")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "maxResults", valid_601842
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
  var valid_601856 = header.getOrDefault("X-Amz-Target")
  valid_601856 = validateParameter(valid_601856, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedAccountsForOrganization"))
  if valid_601856 != nil:
    section.add "X-Amz-Target", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Signature")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Signature", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Content-Sha256", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Date")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Date", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Credential")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Credential", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Security-Token")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Security-Token", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Algorithm")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Algorithm", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-SignedHeaders", valid_601863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601887: Call_DescribeAffectedAccountsForOrganization_601727;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_601887.validator(path, query, header, formData, body)
  let scheme = call_601887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601887.url(scheme.get, call_601887.host, call_601887.base,
                         call_601887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601887, url, valid)

proc call*(call_601958: Call_DescribeAffectedAccountsForOrganization_601727;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeAffectedAccountsForOrganization
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_601959 = newJObject()
  var body_601961 = newJObject()
  add(query_601959, "nextToken", newJString(nextToken))
  if body != nil:
    body_601961 = body
  add(query_601959, "maxResults", newJString(maxResults))
  result = call_601958.call(nil, query_601959, nil, nil, body_601961)

var describeAffectedAccountsForOrganization* = Call_DescribeAffectedAccountsForOrganization_601727(
    name: "describeAffectedAccountsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedAccountsForOrganization",
    validator: validate_DescribeAffectedAccountsForOrganization_601728, base: "/",
    url: url_DescribeAffectedAccountsForOrganization_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAffectedEntities_602000 = ref object of OpenApiRestCall_601389
proc url_DescribeAffectedEntities_602002(protocol: Scheme; host: string;
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

proc validate_DescribeAffectedEntities_602001(path: JsonNode; query: JsonNode;
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
  var valid_602003 = query.getOrDefault("nextToken")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "nextToken", valid_602003
  var valid_602004 = query.getOrDefault("maxResults")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "maxResults", valid_602004
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
  var valid_602005 = header.getOrDefault("X-Amz-Target")
  valid_602005 = validateParameter(valid_602005, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntities"))
  if valid_602005 != nil:
    section.add "X-Amz-Target", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Signature")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Signature", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Content-Sha256", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Date")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Date", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Credential")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Credential", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Security-Token")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Security-Token", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Algorithm")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Algorithm", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-SignedHeaders", valid_602012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602014: Call_DescribeAffectedEntities_602000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  let valid = call_602014.validator(path, query, header, formData, body)
  let scheme = call_602014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602014.url(scheme.get, call_602014.host, call_602014.base,
                         call_602014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602014, url, valid)

proc call*(call_602015: Call_DescribeAffectedEntities_602000; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeAffectedEntities
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602016 = newJObject()
  var body_602017 = newJObject()
  add(query_602016, "nextToken", newJString(nextToken))
  if body != nil:
    body_602017 = body
  add(query_602016, "maxResults", newJString(maxResults))
  result = call_602015.call(nil, query_602016, nil, nil, body_602017)

var describeAffectedEntities* = Call_DescribeAffectedEntities_602000(
    name: "describeAffectedEntities", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntities",
    validator: validate_DescribeAffectedEntities_602001, base: "/",
    url: url_DescribeAffectedEntities_602002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAffectedEntitiesForOrganization_602018 = ref object of OpenApiRestCall_601389
proc url_DescribeAffectedEntitiesForOrganization_602020(protocol: Scheme;
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

proc validate_DescribeAffectedEntitiesForOrganization_602019(path: JsonNode;
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
  var valid_602021 = query.getOrDefault("nextToken")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "nextToken", valid_602021
  var valid_602022 = query.getOrDefault("maxResults")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "maxResults", valid_602022
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
  var valid_602023 = header.getOrDefault("X-Amz-Target")
  valid_602023 = validateParameter(valid_602023, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntitiesForOrganization"))
  if valid_602023 != nil:
    section.add "X-Amz-Target", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Signature")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Signature", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Content-Sha256", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Date")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Date", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Credential")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Credential", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Security-Token")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Security-Token", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Algorithm")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Algorithm", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-SignedHeaders", valid_602030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602032: Call_DescribeAffectedEntitiesForOrganization_602018;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ## 
  let valid = call_602032.validator(path, query, header, formData, body)
  let scheme = call_602032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602032.url(scheme.get, call_602032.host, call_602032.base,
                         call_602032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602032, url, valid)

proc call*(call_602033: Call_DescribeAffectedEntitiesForOrganization_602018;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeAffectedEntitiesForOrganization
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602034 = newJObject()
  var body_602035 = newJObject()
  add(query_602034, "nextToken", newJString(nextToken))
  if body != nil:
    body_602035 = body
  add(query_602034, "maxResults", newJString(maxResults))
  result = call_602033.call(nil, query_602034, nil, nil, body_602035)

var describeAffectedEntitiesForOrganization* = Call_DescribeAffectedEntitiesForOrganization_602018(
    name: "describeAffectedEntitiesForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntitiesForOrganization",
    validator: validate_DescribeAffectedEntitiesForOrganization_602019, base: "/",
    url: url_DescribeAffectedEntitiesForOrganization_602020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityAggregates_602036 = ref object of OpenApiRestCall_601389
proc url_DescribeEntityAggregates_602038(protocol: Scheme; host: string;
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

proc validate_DescribeEntityAggregates_602037(path: JsonNode; query: JsonNode;
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
  var valid_602039 = header.getOrDefault("X-Amz-Target")
  valid_602039 = validateParameter(valid_602039, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEntityAggregates"))
  if valid_602039 != nil:
    section.add "X-Amz-Target", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Signature")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Signature", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Content-Sha256", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Date")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Date", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Credential")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Credential", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Security-Token")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Security-Token", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Algorithm")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Algorithm", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-SignedHeaders", valid_602046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602048: Call_DescribeEntityAggregates_602036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ## 
  let valid = call_602048.validator(path, query, header, formData, body)
  let scheme = call_602048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602048.url(scheme.get, call_602048.host, call_602048.base,
                         call_602048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602048, url, valid)

proc call*(call_602049: Call_DescribeEntityAggregates_602036; body: JsonNode): Recallable =
  ## describeEntityAggregates
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ##   body: JObject (required)
  var body_602050 = newJObject()
  if body != nil:
    body_602050 = body
  result = call_602049.call(nil, nil, nil, nil, body_602050)

var describeEntityAggregates* = Call_DescribeEntityAggregates_602036(
    name: "describeEntityAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEntityAggregates",
    validator: validate_DescribeEntityAggregates_602037, base: "/",
    url: url_DescribeEntityAggregates_602038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventAggregates_602051 = ref object of OpenApiRestCall_601389
proc url_DescribeEventAggregates_602053(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventAggregates_602052(path: JsonNode; query: JsonNode;
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
  var valid_602054 = query.getOrDefault("nextToken")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "nextToken", valid_602054
  var valid_602055 = query.getOrDefault("maxResults")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "maxResults", valid_602055
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
  var valid_602056 = header.getOrDefault("X-Amz-Target")
  valid_602056 = validateParameter(valid_602056, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventAggregates"))
  if valid_602056 != nil:
    section.add "X-Amz-Target", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Signature")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Signature", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Content-Sha256", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Date")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Date", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Credential")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Credential", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Security-Token")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Security-Token", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Algorithm")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Algorithm", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-SignedHeaders", valid_602063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602065: Call_DescribeEventAggregates_602051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  let valid = call_602065.validator(path, query, header, formData, body)
  let scheme = call_602065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602065.url(scheme.get, call_602065.host, call_602065.base,
                         call_602065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602065, url, valid)

proc call*(call_602066: Call_DescribeEventAggregates_602051; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEventAggregates
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602067 = newJObject()
  var body_602068 = newJObject()
  add(query_602067, "nextToken", newJString(nextToken))
  if body != nil:
    body_602068 = body
  add(query_602067, "maxResults", newJString(maxResults))
  result = call_602066.call(nil, query_602067, nil, nil, body_602068)

var describeEventAggregates* = Call_DescribeEventAggregates_602051(
    name: "describeEventAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventAggregates",
    validator: validate_DescribeEventAggregates_602052, base: "/",
    url: url_DescribeEventAggregates_602053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetails_602069 = ref object of OpenApiRestCall_601389
proc url_DescribeEventDetails_602071(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventDetails_602070(path: JsonNode; query: JsonNode;
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
  var valid_602072 = header.getOrDefault("X-Amz-Target")
  valid_602072 = validateParameter(valid_602072, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetails"))
  if valid_602072 != nil:
    section.add "X-Amz-Target", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Signature")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Signature", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Content-Sha256", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Date")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Date", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Credential")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Credential", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Security-Token")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Security-Token", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Algorithm")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Algorithm", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-SignedHeaders", valid_602079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602081: Call_DescribeEventDetails_602069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, and so on, as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ## 
  let valid = call_602081.validator(path, query, header, formData, body)
  let scheme = call_602081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602081.url(scheme.get, call_602081.host, call_602081.base,
                         call_602081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602081, url, valid)

proc call*(call_602082: Call_DescribeEventDetails_602069; body: JsonNode): Recallable =
  ## describeEventDetails
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, and so on, as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ##   body: JObject (required)
  var body_602083 = newJObject()
  if body != nil:
    body_602083 = body
  result = call_602082.call(nil, nil, nil, nil, body_602083)

var describeEventDetails* = Call_DescribeEventDetails_602069(
    name: "describeEventDetails", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetails",
    validator: validate_DescribeEventDetails_602070, base: "/",
    url: url_DescribeEventDetails_602071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetailsForOrganization_602084 = ref object of OpenApiRestCall_601389
proc url_DescribeEventDetailsForOrganization_602086(protocol: Scheme; host: string;
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

proc validate_DescribeEventDetailsForOrganization_602085(path: JsonNode;
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
  var valid_602087 = header.getOrDefault("X-Amz-Target")
  valid_602087 = validateParameter(valid_602087, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetailsForOrganization"))
  if valid_602087 != nil:
    section.add "X-Amz-Target", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Signature")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Signature", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Content-Sha256", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Date")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Date", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Credential")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Credential", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Security-Token")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Security-Token", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Algorithm")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Algorithm", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-SignedHeaders", valid_602094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602096: Call_DescribeEventDetailsForOrganization_602084;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events for one or more accounts in your organization. Information includes standard event data (Region, service, and so on, as returned by <a>DescribeEventsForOrganization</a>, a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntitiesForOrganization</a> operation.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_602096.validator(path, query, header, formData, body)
  let scheme = call_602096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602096.url(scheme.get, call_602096.host, call_602096.base,
                         call_602096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602096, url, valid)

proc call*(call_602097: Call_DescribeEventDetailsForOrganization_602084;
          body: JsonNode): Recallable =
  ## describeEventDetailsForOrganization
  ## <p>Returns detailed information about one or more specified events for one or more accounts in your organization. Information includes standard event data (Region, service, and so on, as returned by <a>DescribeEventsForOrganization</a>, a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntitiesForOrganization</a> operation.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   body: JObject (required)
  var body_602098 = newJObject()
  if body != nil:
    body_602098 = body
  result = call_602097.call(nil, nil, nil, nil, body_602098)

var describeEventDetailsForOrganization* = Call_DescribeEventDetailsForOrganization_602084(
    name: "describeEventDetailsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetailsForOrganization",
    validator: validate_DescribeEventDetailsForOrganization_602085, base: "/",
    url: url_DescribeEventDetailsForOrganization_602086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTypes_602099 = ref object of OpenApiRestCall_601389
proc url_DescribeEventTypes_602101(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventTypes_602100(path: JsonNode; query: JsonNode;
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
  var valid_602102 = query.getOrDefault("nextToken")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "nextToken", valid_602102
  var valid_602103 = query.getOrDefault("maxResults")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "maxResults", valid_602103
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
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventTypes"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_DescribeEventTypes_602099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_DescribeEventTypes_602099; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEventTypes
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602115 = newJObject()
  var body_602116 = newJObject()
  add(query_602115, "nextToken", newJString(nextToken))
  if body != nil:
    body_602116 = body
  add(query_602115, "maxResults", newJString(maxResults))
  result = call_602114.call(nil, query_602115, nil, nil, body_602116)

var describeEventTypes* = Call_DescribeEventTypes_602099(
    name: "describeEventTypes", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventTypes",
    validator: validate_DescribeEventTypes_602100, base: "/",
    url: url_DescribeEventTypes_602101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_602117 = ref object of OpenApiRestCall_601389
proc url_DescribeEvents_602119(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEvents_602118(path: JsonNode; query: JsonNode;
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
  var valid_602120 = query.getOrDefault("nextToken")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "nextToken", valid_602120
  var valid_602121 = query.getOrDefault("maxResults")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "maxResults", valid_602121
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
  var valid_602122 = header.getOrDefault("X-Amz-Target")
  valid_602122 = validateParameter(valid_602122, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEvents"))
  if valid_602122 != nil:
    section.add "X-Amz-Target", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Signature")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Signature", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Content-Sha256", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Date")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Date", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Credential")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Credential", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Security-Token")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Security-Token", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Algorithm")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Algorithm", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-SignedHeaders", valid_602129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602131: Call_DescribeEvents_602117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  let valid = call_602131.validator(path, query, header, formData, body)
  let scheme = call_602131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602131.url(scheme.get, call_602131.host, call_602131.base,
                         call_602131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602131, url, valid)

proc call*(call_602132: Call_DescribeEvents_602117; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEvents
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602133 = newJObject()
  var body_602134 = newJObject()
  add(query_602133, "nextToken", newJString(nextToken))
  if body != nil:
    body_602134 = body
  add(query_602133, "maxResults", newJString(maxResults))
  result = call_602132.call(nil, query_602133, nil, nil, body_602134)

var describeEvents* = Call_DescribeEvents_602117(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEvents",
    validator: validate_DescribeEvents_602118, base: "/", url: url_DescribeEvents_602119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventsForOrganization_602135 = ref object of OpenApiRestCall_601389
proc url_DescribeEventsForOrganization_602137(protocol: Scheme; host: string;
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

proc validate_DescribeEventsForOrganization_602136(path: JsonNode; query: JsonNode;
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
  var valid_602138 = query.getOrDefault("nextToken")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "nextToken", valid_602138
  var valid_602139 = query.getOrDefault("maxResults")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "maxResults", valid_602139
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
  var valid_602140 = header.getOrDefault("X-Amz-Target")
  valid_602140 = validateParameter(valid_602140, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventsForOrganization"))
  if valid_602140 != nil:
    section.add "X-Amz-Target", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Signature")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Signature", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Content-Sha256", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Date")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Date", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Credential")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Credential", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Security-Token")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Security-Token", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Algorithm")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Algorithm", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-SignedHeaders", valid_602147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602149: Call_DescribeEventsForOrganization_602135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_602149.validator(path, query, header, formData, body)
  let scheme = call_602149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602149.url(scheme.get, call_602149.host, call_602149.base,
                         call_602149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602149, url, valid)

proc call*(call_602150: Call_DescribeEventsForOrganization_602135; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEventsForOrganization
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602151 = newJObject()
  var body_602152 = newJObject()
  add(query_602151, "nextToken", newJString(nextToken))
  if body != nil:
    body_602152 = body
  add(query_602151, "maxResults", newJString(maxResults))
  result = call_602150.call(nil, query_602151, nil, nil, body_602152)

var describeEventsForOrganization* = Call_DescribeEventsForOrganization_602135(
    name: "describeEventsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventsForOrganization",
    validator: validate_DescribeEventsForOrganization_602136, base: "/",
    url: url_DescribeEventsForOrganization_602137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHealthServiceStatusForOrganization_602153 = ref object of OpenApiRestCall_601389
proc url_DescribeHealthServiceStatusForOrganization_602155(protocol: Scheme;
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

proc validate_DescribeHealthServiceStatusForOrganization_602154(path: JsonNode;
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
  var valid_602156 = header.getOrDefault("X-Amz-Target")
  valid_602156 = validateParameter(valid_602156, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeHealthServiceStatusForOrganization"))
  if valid_602156 != nil:
    section.add "X-Amz-Target", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Signature")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Signature", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Content-Sha256", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Date")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Date", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Credential")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Credential", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Security-Token")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Security-Token", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Algorithm")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Algorithm", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-SignedHeaders", valid_602163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602164: Call_DescribeHealthServiceStatusForOrganization_602153;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## This operation provides status information on enabling or disabling AWS Health to work with your organization. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_602164.validator(path, query, header, formData, body)
  let scheme = call_602164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602164.url(scheme.get, call_602164.host, call_602164.base,
                         call_602164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602164, url, valid)

proc call*(call_602165: Call_DescribeHealthServiceStatusForOrganization_602153): Recallable =
  ## describeHealthServiceStatusForOrganization
  ## This operation provides status information on enabling or disabling AWS Health to work with your organization. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_602165.call(nil, nil, nil, nil, nil)

var describeHealthServiceStatusForOrganization* = Call_DescribeHealthServiceStatusForOrganization_602153(
    name: "describeHealthServiceStatusForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeHealthServiceStatusForOrganization",
    validator: validate_DescribeHealthServiceStatusForOrganization_602154,
    base: "/", url: url_DescribeHealthServiceStatusForOrganization_602155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableHealthServiceAccessForOrganization_602166 = ref object of OpenApiRestCall_601389
proc url_DisableHealthServiceAccessForOrganization_602168(protocol: Scheme;
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

proc validate_DisableHealthServiceAccessForOrganization_602167(path: JsonNode;
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
  var valid_602169 = header.getOrDefault("X-Amz-Target")
  valid_602169 = validateParameter(valid_602169, JString, required = true, default = newJString(
      "AWSHealth_20160804.DisableHealthServiceAccessForOrganization"))
  if valid_602169 != nil:
    section.add "X-Amz-Target", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Signature")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Signature", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Content-Sha256", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Date")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Date", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Credential")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Credential", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Security-Token")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Security-Token", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Algorithm")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Algorithm", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-SignedHeaders", valid_602176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602177: Call_DisableHealthServiceAccessForOrganization_602166;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Calling this operation disables Health from working with AWS Organizations. This does not remove the Service Linked Role (SLR) from the the master account in your organization. Use the IAM console, API, or AWS CLI to remove the SLR if desired. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_602177.validator(path, query, header, formData, body)
  let scheme = call_602177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602177.url(scheme.get, call_602177.host, call_602177.base,
                         call_602177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602177, url, valid)

proc call*(call_602178: Call_DisableHealthServiceAccessForOrganization_602166): Recallable =
  ## disableHealthServiceAccessForOrganization
  ## Calling this operation disables Health from working with AWS Organizations. This does not remove the Service Linked Role (SLR) from the the master account in your organization. Use the IAM console, API, or AWS CLI to remove the SLR if desired. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_602178.call(nil, nil, nil, nil, nil)

var disableHealthServiceAccessForOrganization* = Call_DisableHealthServiceAccessForOrganization_602166(
    name: "disableHealthServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DisableHealthServiceAccessForOrganization",
    validator: validate_DisableHealthServiceAccessForOrganization_602167,
    base: "/", url: url_DisableHealthServiceAccessForOrganization_602168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableHealthServiceAccessForOrganization_602179 = ref object of OpenApiRestCall_601389
proc url_EnableHealthServiceAccessForOrganization_602181(protocol: Scheme;
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

proc validate_EnableHealthServiceAccessForOrganization_602180(path: JsonNode;
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
  var valid_602182 = header.getOrDefault("X-Amz-Target")
  valid_602182 = validateParameter(valid_602182, JString, required = true, default = newJString(
      "AWSHealth_20160804.EnableHealthServiceAccessForOrganization"))
  if valid_602182 != nil:
    section.add "X-Amz-Target", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Signature")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Signature", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Content-Sha256", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Date")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Date", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Credential")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Credential", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Security-Token")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Security-Token", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Algorithm")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Algorithm", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-SignedHeaders", valid_602189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602190: Call_EnableHealthServiceAccessForOrganization_602179;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Calling this operation enables AWS Health to work with AWS Organizations. This applies a Service Linked Role (SLR) to the master account in the organization. To learn more about the steps in this process, visit enabling service access for AWS Health in AWS Organizations. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_602190.validator(path, query, header, formData, body)
  let scheme = call_602190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602190.url(scheme.get, call_602190.host, call_602190.base,
                         call_602190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602190, url, valid)

proc call*(call_602191: Call_EnableHealthServiceAccessForOrganization_602179): Recallable =
  ## enableHealthServiceAccessForOrganization
  ## Calling this operation enables AWS Health to work with AWS Organizations. This applies a Service Linked Role (SLR) to the master account in the organization. To learn more about the steps in this process, visit enabling service access for AWS Health in AWS Organizations. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_602191.call(nil, nil, nil, nil, nil)

var enableHealthServiceAccessForOrganization* = Call_EnableHealthServiceAccessForOrganization_602179(
    name: "enableHealthServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.EnableHealthServiceAccessForOrganization",
    validator: validate_EnableHealthServiceAccessForOrganization_602180,
    base: "/", url: url_EnableHealthServiceAccessForOrganization_602181,
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
