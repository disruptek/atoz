
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "health"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeAffectedAccountsForOrganization_610996 = ref object of OpenApiRestCall_610658
proc url_DescribeAffectedAccountsForOrganization_610998(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAffectedAccountsForOrganization_610997(path: JsonNode;
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
  var valid_611110 = query.getOrDefault("nextToken")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "nextToken", valid_611110
  var valid_611111 = query.getOrDefault("maxResults")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "maxResults", valid_611111
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
  var valid_611125 = header.getOrDefault("X-Amz-Target")
  valid_611125 = validateParameter(valid_611125, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedAccountsForOrganization"))
  if valid_611125 != nil:
    section.add "X-Amz-Target", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Signature")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Signature", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Content-Sha256", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Date")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Date", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Credential")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Credential", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Security-Token")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Security-Token", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Algorithm")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Algorithm", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-SignedHeaders", valid_611132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611156: Call_DescribeAffectedAccountsForOrganization_610996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_611156.validator(path, query, header, formData, body)
  let scheme = call_611156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611156.url(scheme.get, call_611156.host, call_611156.base,
                         call_611156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611156, url, valid)

proc call*(call_611227: Call_DescribeAffectedAccountsForOrganization_610996;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeAffectedAccountsForOrganization
  ## <p>Returns a list of accounts in the organization from AWS Organizations that are affected by the provided event.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611228 = newJObject()
  var body_611230 = newJObject()
  add(query_611228, "nextToken", newJString(nextToken))
  if body != nil:
    body_611230 = body
  add(query_611228, "maxResults", newJString(maxResults))
  result = call_611227.call(nil, query_611228, nil, nil, body_611230)

var describeAffectedAccountsForOrganization* = Call_DescribeAffectedAccountsForOrganization_610996(
    name: "describeAffectedAccountsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedAccountsForOrganization",
    validator: validate_DescribeAffectedAccountsForOrganization_610997, base: "/",
    url: url_DescribeAffectedAccountsForOrganization_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAffectedEntities_611269 = ref object of OpenApiRestCall_610658
proc url_DescribeAffectedEntities_611271(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAffectedEntities_611270(path: JsonNode; query: JsonNode;
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
  var valid_611272 = query.getOrDefault("nextToken")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "nextToken", valid_611272
  var valid_611273 = query.getOrDefault("maxResults")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "maxResults", valid_611273
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
  var valid_611274 = header.getOrDefault("X-Amz-Target")
  valid_611274 = validateParameter(valid_611274, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntities"))
  if valid_611274 != nil:
    section.add "X-Amz-Target", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Signature")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Signature", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Content-Sha256", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Date")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Date", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Credential")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Credential", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Security-Token")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Security-Token", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Algorithm")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Algorithm", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-SignedHeaders", valid_611281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611283: Call_DescribeAffectedEntities_611269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  let valid = call_611283.validator(path, query, header, formData, body)
  let scheme = call_611283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611283.url(scheme.get, call_611283.host, call_611283.base,
                         call_611283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611283, url, valid)

proc call*(call_611284: Call_DescribeAffectedEntities_611269; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeAffectedEntities
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611285 = newJObject()
  var body_611286 = newJObject()
  add(query_611285, "nextToken", newJString(nextToken))
  if body != nil:
    body_611286 = body
  add(query_611285, "maxResults", newJString(maxResults))
  result = call_611284.call(nil, query_611285, nil, nil, body_611286)

var describeAffectedEntities* = Call_DescribeAffectedEntities_611269(
    name: "describeAffectedEntities", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntities",
    validator: validate_DescribeAffectedEntities_611270, base: "/",
    url: url_DescribeAffectedEntities_611271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAffectedEntitiesForOrganization_611287 = ref object of OpenApiRestCall_610658
proc url_DescribeAffectedEntitiesForOrganization_611289(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAffectedEntitiesForOrganization_611288(path: JsonNode;
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
  var valid_611290 = query.getOrDefault("nextToken")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "nextToken", valid_611290
  var valid_611291 = query.getOrDefault("maxResults")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "maxResults", valid_611291
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
  var valid_611292 = header.getOrDefault("X-Amz-Target")
  valid_611292 = validateParameter(valid_611292, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntitiesForOrganization"))
  if valid_611292 != nil:
    section.add "X-Amz-Target", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Signature")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Signature", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Content-Sha256", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Date")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Date", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Credential")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Credential", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Security-Token")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Security-Token", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Algorithm")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Algorithm", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-SignedHeaders", valid_611299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611301: Call_DescribeAffectedEntitiesForOrganization_611287;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ## 
  let valid = call_611301.validator(path, query, header, formData, body)
  let scheme = call_611301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611301.url(scheme.get, call_611301.host, call_611301.base,
                         call_611301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611301, url, valid)

proc call*(call_611302: Call_DescribeAffectedEntitiesForOrganization_611287;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeAffectedEntitiesForOrganization
  ## <p>Returns a list of entities that have been affected by one or more events for one or more accounts in your organization in AWS Organizations, based on the filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service.</p> <p>At least one event ARN and account ID are required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611303 = newJObject()
  var body_611304 = newJObject()
  add(query_611303, "nextToken", newJString(nextToken))
  if body != nil:
    body_611304 = body
  add(query_611303, "maxResults", newJString(maxResults))
  result = call_611302.call(nil, query_611303, nil, nil, body_611304)

var describeAffectedEntitiesForOrganization* = Call_DescribeAffectedEntitiesForOrganization_611287(
    name: "describeAffectedEntitiesForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntitiesForOrganization",
    validator: validate_DescribeAffectedEntitiesForOrganization_611288, base: "/",
    url: url_DescribeAffectedEntitiesForOrganization_611289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityAggregates_611305 = ref object of OpenApiRestCall_610658
proc url_DescribeEntityAggregates_611307(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEntityAggregates_611306(path: JsonNode; query: JsonNode;
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
  var valid_611308 = header.getOrDefault("X-Amz-Target")
  valid_611308 = validateParameter(valid_611308, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEntityAggregates"))
  if valid_611308 != nil:
    section.add "X-Amz-Target", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Signature")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Signature", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Content-Sha256", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Date")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Date", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Credential")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Credential", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Security-Token")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Security-Token", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Algorithm")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Algorithm", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-SignedHeaders", valid_611315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611317: Call_DescribeEntityAggregates_611305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ## 
  let valid = call_611317.validator(path, query, header, formData, body)
  let scheme = call_611317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611317.url(scheme.get, call_611317.host, call_611317.base,
                         call_611317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611317, url, valid)

proc call*(call_611318: Call_DescribeEntityAggregates_611305; body: JsonNode): Recallable =
  ## describeEntityAggregates
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ##   body: JObject (required)
  var body_611319 = newJObject()
  if body != nil:
    body_611319 = body
  result = call_611318.call(nil, nil, nil, nil, body_611319)

var describeEntityAggregates* = Call_DescribeEntityAggregates_611305(
    name: "describeEntityAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEntityAggregates",
    validator: validate_DescribeEntityAggregates_611306, base: "/",
    url: url_DescribeEntityAggregates_611307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventAggregates_611320 = ref object of OpenApiRestCall_610658
proc url_DescribeEventAggregates_611322(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventAggregates_611321(path: JsonNode; query: JsonNode;
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
  var valid_611323 = query.getOrDefault("nextToken")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "nextToken", valid_611323
  var valid_611324 = query.getOrDefault("maxResults")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "maxResults", valid_611324
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
  var valid_611325 = header.getOrDefault("X-Amz-Target")
  valid_611325 = validateParameter(valid_611325, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventAggregates"))
  if valid_611325 != nil:
    section.add "X-Amz-Target", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Signature")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Signature", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Content-Sha256", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Date")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Date", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Credential")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Credential", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Security-Token")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Security-Token", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Algorithm")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Algorithm", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-SignedHeaders", valid_611332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611334: Call_DescribeEventAggregates_611320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  let valid = call_611334.validator(path, query, header, formData, body)
  let scheme = call_611334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611334.url(scheme.get, call_611334.host, call_611334.base,
                         call_611334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611334, url, valid)

proc call*(call_611335: Call_DescribeEventAggregates_611320; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEventAggregates
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611336 = newJObject()
  var body_611337 = newJObject()
  add(query_611336, "nextToken", newJString(nextToken))
  if body != nil:
    body_611337 = body
  add(query_611336, "maxResults", newJString(maxResults))
  result = call_611335.call(nil, query_611336, nil, nil, body_611337)

var describeEventAggregates* = Call_DescribeEventAggregates_611320(
    name: "describeEventAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventAggregates",
    validator: validate_DescribeEventAggregates_611321, base: "/",
    url: url_DescribeEventAggregates_611322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetails_611338 = ref object of OpenApiRestCall_610658
proc url_DescribeEventDetails_611340(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventDetails_611339(path: JsonNode; query: JsonNode;
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
  var valid_611341 = header.getOrDefault("X-Amz-Target")
  valid_611341 = validateParameter(valid_611341, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetails"))
  if valid_611341 != nil:
    section.add "X-Amz-Target", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Signature")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Signature", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Content-Sha256", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Date")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Date", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Credential")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Credential", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Security-Token")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Security-Token", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Algorithm")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Algorithm", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-SignedHeaders", valid_611348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611350: Call_DescribeEventDetails_611338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, and so on, as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ## 
  let valid = call_611350.validator(path, query, header, formData, body)
  let scheme = call_611350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611350.url(scheme.get, call_611350.host, call_611350.base,
                         call_611350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611350, url, valid)

proc call*(call_611351: Call_DescribeEventDetails_611338; body: JsonNode): Recallable =
  ## describeEventDetails
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, and so on, as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ##   body: JObject (required)
  var body_611352 = newJObject()
  if body != nil:
    body_611352 = body
  result = call_611351.call(nil, nil, nil, nil, body_611352)

var describeEventDetails* = Call_DescribeEventDetails_611338(
    name: "describeEventDetails", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetails",
    validator: validate_DescribeEventDetails_611339, base: "/",
    url: url_DescribeEventDetails_611340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetailsForOrganization_611353 = ref object of OpenApiRestCall_610658
proc url_DescribeEventDetailsForOrganization_611355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventDetailsForOrganization_611354(path: JsonNode;
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
  var valid_611356 = header.getOrDefault("X-Amz-Target")
  valid_611356 = validateParameter(valid_611356, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetailsForOrganization"))
  if valid_611356 != nil:
    section.add "X-Amz-Target", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Signature")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Signature", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Content-Sha256", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Date")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Date", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Credential")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Credential", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Security-Token")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Security-Token", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Algorithm")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Algorithm", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-SignedHeaders", valid_611363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611365: Call_DescribeEventDetailsForOrganization_611353;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events for one or more accounts in your organization. Information includes standard event data (Region, service, and so on, as returned by <a>DescribeEventsForOrganization</a>, a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntitiesForOrganization</a> operation.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_611365.validator(path, query, header, formData, body)
  let scheme = call_611365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611365.url(scheme.get, call_611365.host, call_611365.base,
                         call_611365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611365, url, valid)

proc call*(call_611366: Call_DescribeEventDetailsForOrganization_611353;
          body: JsonNode): Recallable =
  ## describeEventDetailsForOrganization
  ## <p>Returns detailed information about one or more specified events for one or more accounts in your organization. Information includes standard event data (Region, service, and so on, as returned by <a>DescribeEventsForOrganization</a>, a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntitiesForOrganization</a> operation.</p> <p>Before you can call this operation, you must first enable AWS Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   body: JObject (required)
  var body_611367 = newJObject()
  if body != nil:
    body_611367 = body
  result = call_611366.call(nil, nil, nil, nil, body_611367)

var describeEventDetailsForOrganization* = Call_DescribeEventDetailsForOrganization_611353(
    name: "describeEventDetailsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetailsForOrganization",
    validator: validate_DescribeEventDetailsForOrganization_611354, base: "/",
    url: url_DescribeEventDetailsForOrganization_611355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTypes_611368 = ref object of OpenApiRestCall_610658
proc url_DescribeEventTypes_611370(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventTypes_611369(path: JsonNode; query: JsonNode;
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
  var valid_611371 = query.getOrDefault("nextToken")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "nextToken", valid_611371
  var valid_611372 = query.getOrDefault("maxResults")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "maxResults", valid_611372
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
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventTypes"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_DescribeEventTypes_611368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_DescribeEventTypes_611368; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEventTypes
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611384 = newJObject()
  var body_611385 = newJObject()
  add(query_611384, "nextToken", newJString(nextToken))
  if body != nil:
    body_611385 = body
  add(query_611384, "maxResults", newJString(maxResults))
  result = call_611383.call(nil, query_611384, nil, nil, body_611385)

var describeEventTypes* = Call_DescribeEventTypes_611368(
    name: "describeEventTypes", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventTypes",
    validator: validate_DescribeEventTypes_611369, base: "/",
    url: url_DescribeEventTypes_611370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_611386 = ref object of OpenApiRestCall_610658
proc url_DescribeEvents_611388(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvents_611387(path: JsonNode; query: JsonNode;
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
  var valid_611389 = query.getOrDefault("nextToken")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "nextToken", valid_611389
  var valid_611390 = query.getOrDefault("maxResults")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "maxResults", valid_611390
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
  var valid_611391 = header.getOrDefault("X-Amz-Target")
  valid_611391 = validateParameter(valid_611391, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEvents"))
  if valid_611391 != nil:
    section.add "X-Amz-Target", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Signature")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Signature", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Content-Sha256", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Date")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Date", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Credential")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Credential", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Security-Token")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Security-Token", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Algorithm")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Algorithm", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-SignedHeaders", valid_611398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611400: Call_DescribeEvents_611386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  let valid = call_611400.validator(path, query, header, formData, body)
  let scheme = call_611400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611400.url(scheme.get, call_611400.host, call_611400.base,
                         call_611400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611400, url, valid)

proc call*(call_611401: Call_DescribeEvents_611386; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEvents
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611402 = newJObject()
  var body_611403 = newJObject()
  add(query_611402, "nextToken", newJString(nextToken))
  if body != nil:
    body_611403 = body
  add(query_611402, "maxResults", newJString(maxResults))
  result = call_611401.call(nil, query_611402, nil, nil, body_611403)

var describeEvents* = Call_DescribeEvents_611386(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEvents",
    validator: validate_DescribeEvents_611387, base: "/", url: url_DescribeEvents_611388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventsForOrganization_611404 = ref object of OpenApiRestCall_610658
proc url_DescribeEventsForOrganization_611406(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventsForOrganization_611405(path: JsonNode; query: JsonNode;
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
  var valid_611407 = query.getOrDefault("nextToken")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "nextToken", valid_611407
  var valid_611408 = query.getOrDefault("maxResults")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "maxResults", valid_611408
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
  var valid_611409 = header.getOrDefault("X-Amz-Target")
  valid_611409 = validateParameter(valid_611409, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventsForOrganization"))
  if valid_611409 != nil:
    section.add "X-Amz-Target", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Signature")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Signature", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Content-Sha256", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Date")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Date", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Credential")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Credential", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Security-Token")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Security-Token", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Algorithm")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Algorithm", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-SignedHeaders", valid_611416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611418: Call_DescribeEventsForOrganization_611404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ## 
  let valid = call_611418.validator(path, query, header, formData, body)
  let scheme = call_611418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611418.url(scheme.get, call_611418.host, call_611418.base,
                         call_611418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611418, url, valid)

proc call*(call_611419: Call_DescribeEventsForOrganization_611404; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEventsForOrganization
  ## <p>Returns information about events across your organization in AWS Organizations, meeting the specified filter criteria. Events are returned in a summary form and do not include the accounts impacted, detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeAffectedAccountsForOrganization</a>, <a>DescribeEventDetailsForOrganization</a>, and <a>DescribeAffectedEntitiesForOrganization</a> operations.</p> <p>If no filter criteria are specified, all events across your organization are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p> <p>Before you can call this operation, you must first enable Health to work with AWS Organizations. To do this, call the <a>EnableHealthServiceAccessForOrganization</a> operation from your organization's master account.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611420 = newJObject()
  var body_611421 = newJObject()
  add(query_611420, "nextToken", newJString(nextToken))
  if body != nil:
    body_611421 = body
  add(query_611420, "maxResults", newJString(maxResults))
  result = call_611419.call(nil, query_611420, nil, nil, body_611421)

var describeEventsForOrganization* = Call_DescribeEventsForOrganization_611404(
    name: "describeEventsForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventsForOrganization",
    validator: validate_DescribeEventsForOrganization_611405, base: "/",
    url: url_DescribeEventsForOrganization_611406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHealthServiceStatusForOrganization_611422 = ref object of OpenApiRestCall_610658
proc url_DescribeHealthServiceStatusForOrganization_611424(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHealthServiceStatusForOrganization_611423(path: JsonNode;
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
  var valid_611425 = header.getOrDefault("X-Amz-Target")
  valid_611425 = validateParameter(valid_611425, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeHealthServiceStatusForOrganization"))
  if valid_611425 != nil:
    section.add "X-Amz-Target", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Signature")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Signature", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Content-Sha256", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Date")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Date", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Credential")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Credential", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Security-Token")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Security-Token", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Algorithm")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Algorithm", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-SignedHeaders", valid_611432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611433: Call_DescribeHealthServiceStatusForOrganization_611422;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## This operation provides status information on enabling or disabling AWS Health to work with your organization. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_611433.validator(path, query, header, formData, body)
  let scheme = call_611433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611433.url(scheme.get, call_611433.host, call_611433.base,
                         call_611433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611433, url, valid)

proc call*(call_611434: Call_DescribeHealthServiceStatusForOrganization_611422): Recallable =
  ## describeHealthServiceStatusForOrganization
  ## This operation provides status information on enabling or disabling AWS Health to work with your organization. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_611434.call(nil, nil, nil, nil, nil)

var describeHealthServiceStatusForOrganization* = Call_DescribeHealthServiceStatusForOrganization_611422(
    name: "describeHealthServiceStatusForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DescribeHealthServiceStatusForOrganization",
    validator: validate_DescribeHealthServiceStatusForOrganization_611423,
    base: "/", url: url_DescribeHealthServiceStatusForOrganization_611424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableHealthServiceAccessForOrganization_611435 = ref object of OpenApiRestCall_610658
proc url_DisableHealthServiceAccessForOrganization_611437(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableHealthServiceAccessForOrganization_611436(path: JsonNode;
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
  var valid_611438 = header.getOrDefault("X-Amz-Target")
  valid_611438 = validateParameter(valid_611438, JString, required = true, default = newJString(
      "AWSHealth_20160804.DisableHealthServiceAccessForOrganization"))
  if valid_611438 != nil:
    section.add "X-Amz-Target", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Signature")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Signature", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Content-Sha256", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Date")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Date", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-Credential")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Credential", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Security-Token")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Security-Token", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Algorithm")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Algorithm", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-SignedHeaders", valid_611445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611446: Call_DisableHealthServiceAccessForOrganization_611435;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Calling this operation disables Health from working with AWS Organizations. This does not remove the Service Linked Role (SLR) from the the master account in your organization. Use the IAM console, API, or AWS CLI to remove the SLR if desired. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_611446.validator(path, query, header, formData, body)
  let scheme = call_611446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611446.url(scheme.get, call_611446.host, call_611446.base,
                         call_611446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611446, url, valid)

proc call*(call_611447: Call_DisableHealthServiceAccessForOrganization_611435): Recallable =
  ## disableHealthServiceAccessForOrganization
  ## Calling this operation disables Health from working with AWS Organizations. This does not remove the Service Linked Role (SLR) from the the master account in your organization. Use the IAM console, API, or AWS CLI to remove the SLR if desired. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_611447.call(nil, nil, nil, nil, nil)

var disableHealthServiceAccessForOrganization* = Call_DisableHealthServiceAccessForOrganization_611435(
    name: "disableHealthServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.DisableHealthServiceAccessForOrganization",
    validator: validate_DisableHealthServiceAccessForOrganization_611436,
    base: "/", url: url_DisableHealthServiceAccessForOrganization_611437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableHealthServiceAccessForOrganization_611448 = ref object of OpenApiRestCall_610658
proc url_EnableHealthServiceAccessForOrganization_611450(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableHealthServiceAccessForOrganization_611449(path: JsonNode;
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
  var valid_611451 = header.getOrDefault("X-Amz-Target")
  valid_611451 = validateParameter(valid_611451, JString, required = true, default = newJString(
      "AWSHealth_20160804.EnableHealthServiceAccessForOrganization"))
  if valid_611451 != nil:
    section.add "X-Amz-Target", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Signature")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Signature", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Content-Sha256", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Date")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Date", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Credential")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Credential", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Security-Token")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Security-Token", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Algorithm")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Algorithm", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-SignedHeaders", valid_611458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611459: Call_EnableHealthServiceAccessForOrganization_611448;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Calling this operation enables AWS Health to work with AWS Organizations. This applies a Service Linked Role (SLR) to the master account in the organization. To learn more about the steps in this process, visit enabling service access for AWS Health in AWS Organizations. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  ## 
  let valid = call_611459.validator(path, query, header, formData, body)
  let scheme = call_611459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611459.url(scheme.get, call_611459.host, call_611459.base,
                         call_611459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611459, url, valid)

proc call*(call_611460: Call_EnableHealthServiceAccessForOrganization_611448): Recallable =
  ## enableHealthServiceAccessForOrganization
  ## Calling this operation enables AWS Health to work with AWS Organizations. This applies a Service Linked Role (SLR) to the master account in the organization. To learn more about the steps in this process, visit enabling service access for AWS Health in AWS Organizations. To call this operation, you must sign in as an IAM user, assume an IAM role, or sign in as the root user (not recommended) in the organization's master account.
  result = call_611460.call(nil, nil, nil, nil, nil)

var enableHealthServiceAccessForOrganization* = Call_EnableHealthServiceAccessForOrganization_611448(
    name: "enableHealthServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com", route: "/#X-Amz-Target=AWSHealth_20160804.EnableHealthServiceAccessForOrganization",
    validator: validate_EnableHealthServiceAccessForOrganization_611449,
    base: "/", url: url_EnableHealthServiceAccessForOrganization_611450,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
